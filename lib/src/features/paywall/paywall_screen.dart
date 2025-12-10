import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/purchase_service.dart';
import '../../i18n/app_localizations.dart';

/// Kategorie für Tabs
enum PaywallCategory { credits, lifetime, subscription }

/// UI-Model für Paywall Items
class PaywallItem {
  final String id;
  final String title;
  final String subtitle;
  final String price;
  final bool isLifetime;
  final bool isCredit;
  final bool isBestValue;
  final Package? realPackage;

  PaywallItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isLifetime,
    required this.isCredit,
    this.isBestValue = false,
    this.realPackage,
  });
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = true;
  bool _isTestMode = false;
  
  // Aktive Kategorie (Standard: Subscription)
  PaywallCategory _selectedCategory = PaywallCategory.subscription;

  // Listen für die Kategorien
  List<PaywallItem> _subscriptionItems = [];
  List<PaywallItem> _lifetimeItems = [];
  List<PaywallItem> _creditItems = [];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    
    try {
      final offerings = await PurchaseService().getOfferings();
      
      if (offerings != null && (offerings.current != null || offerings.all.isNotEmpty)) {
        final t = AppLocalizations.of(context);
        _categorizeRealPackages(offerings, t);
        _isTestMode = false;
      } else {
        print('⚠️ Keine RevenueCat Daten gefunden. Aktiviere Design-Modus.');
        final t = AppLocalizations.of(context);
        _loadMockData(t);
        _isTestMode = true;
      }
    } catch (e) {
      print('❌ Fehler: $e. Aktiviere Design-Modus.');
      final t = AppLocalizations.of(context);
      _loadMockData(t);
      _isTestMode = true;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _loadMockData(AppLocalizations t) {
    _subscriptionItems = [
      PaywallItem(
        id: 'pro_monthly',
        title: t.tr('paywall.pro_subscription_monthly'),
        subtitle: t.tr('paywall.per_month'),
        price: '4,99 €',
        isLifetime: false,
        isCredit: false,
      ),
      PaywallItem(
        id: 'pro_yearly',
        title: t.tr('paywall.pro_subscription_yearly'),
        subtitle: t.tr('paywall.per_year'),
        price: '39,99 €',
        isLifetime: false,
        isCredit: false,
        isBestValue: true,
      ),
    ];

    _lifetimeItems = [
      PaywallItem(
        id: 'lifetime',
        title: 'Lifetime Unlock',
        subtitle: t.tr('paywall.one_time'),
        price: '19,99 €',
        isLifetime: true,
        isCredit: false,
        isBestValue: true,
      ),
    ];

    _creditItems = [
      PaywallItem(
        id: 'credits_10',
        title: '10 Credits',
        subtitle: t.tr('paywall.one_time'),
        price: '2,49 €',
        isLifetime: false,
        isCredit: true,
      ),
      PaywallItem(
        id: 'credits_25',
        title: '25 Credits',
        subtitle: t.tr('paywall.one_time'),
        price: '5,49 €',
        isLifetime: false,
        isCredit: true,
        isBestValue: true,
      ),
    ];
  }

  void _categorizeRealPackages(Offerings offerings, AppLocalizations t) {
    final allPackages = <Package>[];
    final uniqueIds = <String>{};

    void addUnique(List<Package> packages) {
      for (var p in packages) {
        if (!uniqueIds.contains(p.identifier)) {
          uniqueIds.add(p.identifier);
          allPackages.add(p);
        }
      }
    }

    if (offerings.current != null) addUnique(offerings.current!.availablePackages);
    for (var o in offerings.all.values) {
      if (o.identifier == offerings.current?.identifier) continue;
      addUnique(o.availablePackages);
    }

    _subscriptionItems.clear();
    _lifetimeItems.clear();
    _creditItems.clear();

    for (var package in allPackages) {
      final id = package.storeProduct.identifier.toLowerCase();
      final pkgId = package.identifier.toLowerCase();
      
      bool isCredit = id.contains('credit') || pkgId.contains('credit') || id.contains('token');
      bool isLifetime = id.contains('lifetime');
      
      // Titel Bereinigung
      String title = package.storeProduct.title;
      if (title.contains('(')) title = title.substring(0, title.indexOf('(')).trim();
      
      String subtitle = "";
      if (isCredit || isLifetime) {
        subtitle = t.tr('paywall.one_time'); // Lokalisiert
      } else {
         if (package.packageType == PackageType.monthly) subtitle = t.tr('paywall.per_month');
         else if (package.packageType == PackageType.annual) subtitle = t.tr('paywall.per_year');
      }

      final item = PaywallItem(
        id: package.identifier,
        title: title,
        subtitle: subtitle,
        price: package.storeProduct.priceString,
        isLifetime: isLifetime,
        isCredit: isCredit,
        realPackage: package,
        isBestValue: package.packageType == PackageType.annual || isLifetime,
      );

      if (isCredit) {
        _creditItems.add(item);
      } else if (isLifetime) {
        _lifetimeItems.add(item);
      } else {
        _subscriptionItems.add(item);
      }
    }
    
    // Sortieren
    _sortItems(_subscriptionItems);
    _sortItems(_creditItems);
    // Lifetime meist nur eins, aber sicherheitshalber
    _sortItems(_lifetimeItems);
  }

  void _sortItems(List<PaywallItem> items) {
    items.sort((a, b) {
      if (a.realPackage != null && b.realPackage != null) {
        return a.realPackage!.storeProduct.price.compareTo(b.realPackage!.storeProduct.price);
      }
      return 0; // Mock Data Order beibehalten
    });
  }

  Future<void> _onItemTapped(PaywallItem item) async {
    if (_isTestMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎨 Design-Modus: Kauf erfolgreich simuliert!'),
          backgroundColor: Colors.orange,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.pop();
      return;
    }

    if (item.realPackage == null) return;

    setState(() => _isLoading = true);
    final success = await PurchaseService().purchasePackage(item.realPackage!);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tr('paywall.purchase_success')),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isTestMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎨 Design-Modus: Restore simuliert')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    await PurchaseService().restorePurchases();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tr('paywall.restore_success')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    // Dynamischer Text basierend auf Kategorie
    String descriptionText = "";
    List<PaywallItem> currentItems = [];

    switch (_selectedCategory) {
      case PaywallCategory.credits:
        descriptionText = t.tr('paywall.desc_credits');
        currentItems = _creditItems;
        break;
      case PaywallCategory.lifetime:
        descriptionText = t.tr('paywall.desc_lifetime');
        currentItems = _lifetimeItems;
        break;
      case PaywallCategory.subscription:
        descriptionText = t.tr('paywall.desc_subscription');
        currentItems = _subscriptionItems;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2028),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.tr('paywall.title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isTestMode)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    "DESIGN MODE",
                    style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB129)))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        
                        // App Logo & Headline
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB129).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Dynamische Headline
                        Text(
                          t.tr('paywall.headline'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            descriptionText, // DYNAMISCHER TEXT
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Features List (Passt sich evtl. an? Hier statisch, da Feature Set meist gleich ist)
                        // Du könntest hier auch switch(_selectedCategory) machen für unterschiedliche Features
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildFeaturesList(t),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // TABS (Toggle Buttons)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2028),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                _buildTabButton(t, PaywallCategory.credits, t.tr('paywall.tab_credits')),
                                _buildTabButton(t, PaywallCategory.lifetime, t.tr('paywall.tab_lifetime')),
                                _buildTabButton(t, PaywallCategory.subscription, t.tr('paywall.tab_subscription')),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // PACKAGE LIST (Dynamisch)
                        if (currentItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: currentItems
                                  .map((item) => _buildPackageCard(item))
                                  .toList(),
                            ),
                          )
                        else
                           Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              t.tr('paywall.no_offers'),
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          ),
                          
                        const SizedBox(height: 16),
                        
                        // Restore Link
                        TextButton(
                          onPressed: _restorePurchases,
                          child: Text(
                            t.tr('paywall.restore'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              decoration: TextDecoration.underline,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabButton(AppLocalizations t, PaywallCategory category, String label) {
    final bool isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFB129) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(AppLocalizations t) {
    return Column(
      children: [
        // Credits: Nur KI-Features
        if (_selectedCategory == PaywallCategory.credits) ...[
          _buildFeature(Icons.bolt, t.tr('paywall.feature_ai_instant')),
          _buildFeature(Icons.chat, t.tr('paywall.feature_ai_credits')),
        ],
        
        // Lifetime: NUR KFZ-Kosten + Export
        if (_selectedCategory == PaywallCategory.lifetime) ...[
          _buildFeature(Icons.attach_money, t.tr('paywall.feature_costs')),
          _buildFeature(Icons.file_download, t.tr('paywall.feature_export_costs')),
        ],
        
        // Pro Abo: Kosten + Wartungen + KI + Export
        if (_selectedCategory == PaywallCategory.subscription) ...[
          _buildFeature(Icons.attach_money, t.tr('paywall.feature_costs')),
          _buildFeature(Icons.build, t.tr('paywall.feature_maintenance_all')),
          _buildFeature(Icons.file_download, t.tr('paywall.feature_export_all')),
          _buildFeature(Icons.chat, t.tr('paywall.feature_ai_unlimited')),
          _buildFeature(Icons.notifications_active, t.tr('paywall.feature_reminders')),
        ],
      ],
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Kompakter
      child: Row(
        children: [
          Container(
            width: 40, // Kleiner
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2028),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFFB129), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PaywallItem item) {
    final t = AppLocalizations.of(context);
    final bool isHighlight = item.isBestValue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2028),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFFB129) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onItemTapped(item),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16), // Kompakteres Padding
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.subtitle.isNotEmpty)
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.price,
                          style: const TextStyle(
                            color: Color(0xFFFFB129),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB129),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.tr('paywall.buy_button'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isHighlight)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB129),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      t.tr('paywall.best_value'),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
