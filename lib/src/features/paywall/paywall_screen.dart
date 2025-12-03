import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/purchase_service.dart';
import '../../i18n/app_localizations.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;
  int _selectedTabIndex = 1; // 0=Credits, 1=Lifetime, 2=Pro

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    final offerings = await PurchaseService().getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _buy(Package package) async {
    setState(() => _isLoading = true);
    final success = await PurchaseService().purchasePackage(package);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kauf erfolgreich! Danke für deinen Support.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    await PurchaseService().restorePurchases();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Käufe wiederhergestellt.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.tr('paywall.title'),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB129)))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFB129), Color(0xFFFF8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.workspace_premium, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        t.tr('paywall.headline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        t.tr('paywall.subheadline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                      ),
                    ],
                  ),
                ),
                
                // Benefits Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.tr('paywall.benefits_title'),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                      SizedBox(height: 16),
                      _buildBenefit(Icons.attach_money, t.tr('paywall.benefit_costs')),
                      _buildBenefit(Icons.smart_toy, t.tr('paywall.benefit_ai')),
                      _buildBenefit(Icons.notifications_active, t.tr('paywall.benefit_notifications')),
                      _buildBenefit(Icons.file_download, t.tr('paywall.benefit_export')),
                      _buildBenefit(Icons.no_accounts, t.tr('paywall.benefit_no_ads')),
                    ],
                  ),
                ),
                
                // Tab Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildTab(0, 'Credits'),
                      SizedBox(width: 12),
                      _buildTab(1, 'Lifetime'),
                      SizedBox(width: 12),
                      _buildTab(2, 'Pro Abo'),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Pricing Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPricingSection(),
                ),
                
                SizedBox(height: 24),
                
                // Restore Button
                Center(
                  child: TextButton(
                    onPressed: _restore,
                    child: Text(
                      t.tr('paywall.restore_purchases'),
                      style: TextStyle(color: Colors.black54, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                
                SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFFB129).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFFFFB129), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFFFB129) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Color(0xFFFFB129) : Colors.grey.shade300),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.black54,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    if (_offerings?.current == null || _offerings!.current!.availablePackages.isEmpty) {
      return Center(
        child: Text(
          'Keine Angebote verfügbar',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final packages = _offerings!.current!.availablePackages;
    
    switch (_selectedTabIndex) {
      case 0: // Credits
        final creditPackages = packages.where((p) => 
          p.storeProduct.identifier.contains('credit') || 
          p.storeProduct.identifier.contains('5') ||
          p.storeProduct.identifier.contains('10') ||
          p.storeProduct.identifier.contains('25')
        ).toList();
        return Column(
          children: creditPackages.map((p) => _buildPackageCard(
            p,
            '${p.storeProduct.title}',
            'Für KI-Diagnosen & Chatbot',
          )).toList(),
        );
        
      case 1: // Lifetime
        final lifetimePackage = packages.firstWhere(
          (p) => p.storeProduct.identifier.contains('lifetime'),
          orElse: () => packages.first,
        );
        return _buildPackageCard(
          lifetimePackage,
          '🚗 Lifetime Unlock',
          'Alle KFZ-Kosten Kategorien für immer freischalten',
          isRecommended: true,
        );
        
      case 2: // Pro
        final proPackages = packages.where((p) => 
          p.storeProduct.identifier.contains('pro') ||
          p.storeProduct.identifier.contains('premium')
        ).toList();
        return Column(
          children: proPackages.map((p) => _buildPackageCard(
            p,
            '⭐ ${p.storeProduct.title}',
            'Alle Features + unbegrenzte KI-Nutzung',
          )).toList(),
        );
        
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildPackageCard(Package package, String title, String subtitle, {bool isRecommended = false}) {
    final product = package.storeProduct;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? Color(0xFFFFB129) : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: [
          if (isRecommended)
            BoxShadow(
              color: Color(0xFFFFB129).withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFFB129),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                '⭐ EMPFOHLEN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.priceString,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFB129),
                          ),
                        ),
                        if (product.subscriptionPeriod != null)
                          Text(
                            'pro ${product.subscriptionPeriod}',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _buy(package),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFB129),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Kaufen',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
