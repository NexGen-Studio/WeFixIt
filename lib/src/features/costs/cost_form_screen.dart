import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import purchases_flutter
import '../../i18n/app_localizations.dart';
import '../../services/costs_service.dart';
import '../../services/category_service.dart';
import '../../services/achievements_service.dart';
import '../../services/purchase_service.dart';
import '../../models/vehicle_cost.dart';
import '../../models/cost_category.dart';
import 'dart:io';

/// Formular zum Erstellen/Bearbeiten von Kosteneinträgen
class CostFormScreen extends StatefulWidget {
  final String? costId; // null = Neu erstellen

  const CostFormScreen({Key? key, this.costId}) : super(key: key);

  @override
  State<CostFormScreen> createState() => _CostFormScreenState();
}

class _CostFormScreenState extends State<CostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CostsService _costsService = CostsService();
  final CategoryService _categoryService = CategoryService();
  final ImagePicker _picker = ImagePicker();

  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Treibstoff-spezifisch
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _pricePerLiterController = TextEditingController();
  final TextEditingController _tripDistanceController = TextEditingController();
  final TextEditingController _gasStationController = TextEditingController();

  List<CostCategory> _categories = [];
  List<String> _gasStationSuggestions = [];
  CostCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isFullTank = false;
  bool _isIncome = false; // Einnahme oder Ausgabe
  FuelType? _selectedFuelType;
  List<File> _selectedPhotos = [];
  bool _isLoading = false;
  
  // Monetarisierung
  bool _hasLifetimeUnlock = false;
  bool _isPro = false;
  bool _isSaving = false;
  
  // Zeitraum-Feature für Versicherung/Steuer/Kredit
  DateTime? _periodStartDate;
  DateTime? _periodEndDate;
  bool _isMonthlyAmount = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPurchaseStatus();
  }

  Future<void> _loadPurchaseStatus() async {
    try {
      final purchaseService = PurchaseService();
      final hasUnlock = await purchaseService.hasCostsUnlock();
      final isPro = await purchaseService.isPro();
      if (mounted) {
        setState(() {
          _hasLifetimeUnlock = hasUnlock;
          _isPro = isPro;
        });
      }
    } catch (e) {
      print('Error loading purchase status: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    _litersController.dispose();
    _pricePerLiterController.dispose();
    _tripDistanceController.dispose();
    _gasStationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final allCategories = await _categoryService.fetchAllCategories();
      final suggestions = await _costsService.getGasStationSuggestions();
      
      // Filtere Wartungskategorien heraus (die automatisch aus Wartungen erstellt wurden)
      final maintenanceCategoryNames = [
        'Ölwechsel', 'Oil Change',
        'Reifenwechsel', 'Tire Change',
        'Bremsen', 'Brakes',
        'TÜV/AU', 'TÜV', 'Inspection',
        'Inspektion',
        'Batterie', 'Battery',
        'Filter',
      ];
      
      final categories = allCategories.where((cat) {
        // System-Kategorien immer anzeigen
        if (cat.isSystem) return true;
        // Custom-Kategorien NUR anzeigen wenn sie NICHT aus Wartungen stammen
        return !maintenanceCategoryNames.any((name) => 
          cat.name.toLowerCase().contains(name.toLowerCase()) ||
          name.toLowerCase().contains(cat.name.toLowerCase())
        );
      }).toList();

      setState(() {
        _categories = categories;
        _gasStationSuggestions = suggestions;
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
      });

      // Wenn Bearbeiten-Modus: Daten laden
      if (widget.costId != null) {
        final cost = await _costsService.fetchCostById(widget.costId!);
        if (cost != null) {
          _fillFormFromCost(cost);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fillFormFromCost(VehicleCost cost) {
    setState(() {
      _titleController.text = cost.title;
      _amountController.text = cost.amount.toStringAsFixed(2);
      _mileageController.text = cost.mileage?.toString() ?? '';
      _notesController.text = cost.notes ?? '';
      _selectedDate = cost.date;
      _isIncome = cost.isIncome;
      
      // Zeitraum-Felder
      _periodStartDate = cost.periodStartDate;
      _periodEndDate = cost.periodEndDate;
      _isMonthlyAmount = cost.isMonthlyAmount;
      
      _selectedCategory = _categories.firstWhere(
        (c) => c.id == cost.categoryId,
        orElse: () => _categories.first,
      );

      if (cost.isRefueling) {
        _litersController.text = cost.fuelAmountLiters?.toStringAsFixed(2) ?? '';
        _pricePerLiterController.text = cost.pricePerLiter?.toStringAsFixed(3) ?? '';
        _tripDistanceController.text = cost.tripDistance?.toString() ?? '';
        _gasStationController.text = cost.gasStation ?? '';
        _isFullTank = cost.isFullTank;
        _selectedFuelType = FuelType.fromString(cost.fuelType);
      }
    });
  }

  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      setState(() {
        _selectedPhotos.addAll(images.map((x) => File(x.path)));
      });
    } catch (e) {
      print('Error picking photos: $e');
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    setState(() => _isSaving = true);

    try {
      // Auto-Zeitraum für Versicherung/Steuer/Maut wenn nicht gesetzt
      DateTime? finalPeriodStart = _periodStartDate;
      DateTime? finalPeriodEnd = _periodEndDate;
      bool finalIsMonthlyAmount = _isMonthlyAmount;
      
      if (_isPeriodCategory() && _periodStartDate == null && _periodEndDate == null) {
        // Kein Zeitraum eingegeben → Automatisch 12 Monate
        finalPeriodStart = _selectedDate;
        finalPeriodEnd = DateTime(_selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
        finalIsMonthlyAmount = false; // Gesamtbetrag für 12 Monate
      }
      
      final cost = VehicleCost(
        id: widget.costId ?? '',
        userId: '',
        categoryId: _selectedCategory!.id,
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        mileage: _mileageController.text.isNotEmpty 
            ? int.parse(_mileageController.text) 
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        
        // Einnahme oder Ausgabe
        isIncome: _isIncome,
        
        // Zeitraum-Felder (mit Auto-Zeitraum)
        periodStartDate: finalPeriodStart,
        periodEndDate: finalPeriodEnd,
        isMonthlyAmount: finalIsMonthlyAmount,
        
        // Treibstoff-Felder
        isRefueling: _isFuelCategory(),
        fuelType: _selectedFuelType?.value,
        fuelAmountLiters: _litersController.text.isNotEmpty 
            ? double.parse(_litersController.text) 
            : null,
        pricePerLiter: _pricePerLiterController.text.isNotEmpty 
            ? double.parse(_pricePerLiterController.text) 
            : null,
        tripDistance: _tripDistanceController.text.isNotEmpty 
            ? int.parse(_tripDistanceController.text) 
            : null,
        gasStation: _gasStationController.text.isNotEmpty 
            ? _gasStationController.text 
            : null,
        isFullTank: _isFullTank,
        
        // TODO: Fotos hochladen zu Supabase Storage
        photos: [],
      );

      if (widget.costId != null) {
        await _costsService.updateCost(widget.costId!, cost);
      } else {
        await _costsService.createCost(cost);
        
        try {
          // Achievement-Check nach Erstellen
          final achievementsService = AchievementsService(_costsService);
          final newAchievements = await achievementsService.checkAchievements();
          
          if (newAchievements.isNotEmpty && mounted) {
            await _showAchievementDialog(newAchievements.first);
          }
        } catch (e) {
          print('Error checking achievements: $e');
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      print('Error saving cost: $e');
      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.tr('costs.error_saving')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showAchievementDialog(dynamic achievement) async {
    final t = AppLocalizations.of(context);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151C23),
        title: Row(
          children: [
            Icon(achievement.icon, color: achievement.color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.tr(achievement.titleKey),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          t.tr(achievement.descriptionKey),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.tr('common.ok')),
          ),
        ],
      ),
    );
  }

  bool _isFuelCategory() {
    return _selectedCategory?.name == 'Treibstoff';
  }
  
  bool _isPeriodCategory() {
    final categoryName = _selectedCategory?.name;
    return categoryName == 'Versicherung' || 
           categoryName == 'Steuer' || 
           categoryName == 'Maut & Vignette';
  }
  
  bool _isCategoryUnlocked(CostCategory category) {
    // Pro/Lifetime User: Alle Kategorien freigeschaltet
    if (_hasLifetimeUnlock || _isPro) return true;
    
    // Free User: Nur nicht-gesperrte Kategorien (is_locked = false)
    return !category.isLocked;
  }
  
  Future<void> _showPaywallDialog() async {
    final t = AppLocalizations.of(context);
    
    // Lade Preise
    String lifetimePrice = '1,99€';
    String monthlyPrice = '4,99€';
    
    try {
      final offerings = await PurchaseService().getOfferings();
      if (offerings != null && offerings.current != null) {
        final current = offerings.current!;
        // Suche nach passenden Paketen
        final lifetimePkg = current.availablePackages.firstWhere(
          (p) => p.packageType == PackageType.lifetime || p.identifier.contains('lifetime'),
          orElse: () => current.availablePackages.first, // Fallback, aber riskant -> besser checken
        );
        // Check if it really looks like lifetime if we used fallback logic blindly
        if (lifetimePkg.packageType == PackageType.lifetime || lifetimePkg.identifier.contains('lifetime')) {
             lifetimePrice = lifetimePkg.storeProduct.priceString;
        }

        final monthlyPkg = current.monthly;
        if (monthlyPkg != null) {
          monthlyPrice = monthlyPkg.storeProduct.priceString;
        }
      }
    } catch (e) {
      print('Error loading prices for dialog: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.92,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: Color(0xFFFFB129), size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          t.tr('costs.category_locked_title'),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    t.tr('costs.category_locked_message'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  SizedBox(height: 20),
                  Text(
                    t.tr('costs.unlock_options'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SizedBox(height: 16),
                  _buildPriceRow(t.tr('costs.lifetime_unlock'), lifetimePrice),
                  SizedBox(height: 12),
                  _buildPriceRow(t.tr('costs.pro_unlock'), '$monthlyPrice / ${t.tr('repeat.month')}'),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          t.tr('common.cancel'), 
                          style: const TextStyle(color: Colors.white70, fontSize: 14)
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/paywall');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB129),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        child: Text(t.tr('costs.go_to_paywall')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xFFFFB129), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Text(
          price,
          style: const TextStyle(color: Color(0xFFFFB129), fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F141A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF151C23),
          title: Text(widget.costId != null 
              ? t.tr('costs.edit_entry') 
              : t.tr('costs.add_entry')),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFFFB129)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.costId != null 
              ? t.tr('costs.edit_entry') 
              : t.tr('costs.add_entry'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          physics: const ClampingScrollPhysics(),
          cacheExtent: 1000,
          children: [
            // Kategorie
            Text(
              t.tr('costs.category_field'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CostCategory>(
              value: _selectedCategory,
              decoration: _inputDecoration(t.tr('costs.select_category')),
              dropdownColor: const Color(0xFF1A2028),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              items: _categories.map((cat) {
                final isUnlocked = _isCategoryUnlocked(cat);
                // Cache icon and color
                final icon = CostCategory.getIconData(cat.iconName);
                final color = CostCategory.hexToColor(cat.colorHex);
                
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: isUnlocked ? color : Colors.grey),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          cat.getLocalizedName(t),
                          style: TextStyle(color: isUnlocked ? Colors.white : Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isUnlocked) const SizedBox(width: 8),
                      if (!isUnlocked) const Icon(Icons.lock, size: 16, color: Color(0xFFFFB129)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                // Prüfe ob Kategorie freigeschaltet ist
                if (value != null && !_isCategoryUnlocked(value)) {
                  _showPaywallDialog();
                  return;
                }
                
                setState(() {
                  _selectedCategory = value;
                  // Automatisch isIncome setzen wenn Kategorie 'Einnahmen'
                  _isIncome = value?.name == 'Einnahmen';
                  // Reset Treibstoff-Felder wenn Kategorie gewechselt
                  if (!_isFuelCategory()) {
                    _litersController.clear();
                    _pricePerLiterController.clear();
                    _tripDistanceController.clear();
                    _gasStationController.clear();
                    _isFullTank = false;
                  }
                  // Reset Zeitraum-Felder wenn Kategorie gewechselt
                  if (!_isPeriodCategory()) {
                    _periodStartDate = null;
                    _periodEndDate = null;
                    _isMonthlyAmount = false;
                  }
                });
              },
              validator: (value) => value == null ? t.tr('costs.please_select_category') : null,
            ),
            const SizedBox(height: 20),

            // Titel
            Text(
              t.tr('costs.title_field'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(t.tr('costs.title_hint')),
              style: const TextStyle(color: Colors.white),
              validator: (value) => value?.isEmpty ?? true ? t.tr('costs.please_enter_title') : null,
            ),
            const SizedBox(height: 20),

            // Datum & Betrag (Row)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.tr('costs.date'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFFFB129),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2028),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd.MM.yyyy').format(_selectedDate),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.tr('costs.amount'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        onChanged: (value) {
                          if (_isPeriodCategory() && _isMonthlyAmount) setState(() {});
                        },
                        decoration: _inputDecoration('0.00'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return t.tr('costs.please_enter_amount');
                          if (double.tryParse(value!) == null) return t.tr('costs.invalid_amount');
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kilometerstand
            Text(
              t.tr('costs.mileage'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mileageController,
              decoration: _inputDecoration(t.tr('costs.mileage_hint')),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),

            // Treibstoff-spezifische Felder (nur wenn Kategorie = fuel)
            if (_isFuelCategory()) ..._buildFuelFields(t),
            
            // Zeitraum-Felder (nur für Versicherung/Steuer/Kredit)
            if (_isPeriodCategory()) ..._buildPeriodFields(t),

            // Fotos
            Text(
              t.tr('costs.receipts'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(t.tr('costs.add_photo')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (_selectedPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedPhotos.map((photo) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            photo,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedPhotos.remove(photo));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Notizen
            Text(
              t.tr('costs.notes'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: _inputDecoration(t.tr('costs.notes_hint')),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Speichern-Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB129),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                  : Text(t.tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFuelFields(AppLocalizations t) {
    return [
      // Tankstelle (mit Autocomplete)
      Text(
        t.tr('costs.gas_station'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _gasStationController,
        decoration: _inputDecoration(t.tr('costs.gas_station_hint')),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 20),

      // Liter & Preis/Liter
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tr('costs.liters'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _litersController,
                  decoration: _inputDecoration('0.00'),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tr('costs.price_per_liter'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pricePerLiterController,
                  decoration: _inputDecoration('0.000'),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),

      // Vollbetankung & Strecke
      CheckboxListTile(
        value: _isFullTank,
        onChanged: (value) => setState(() => _isFullTank = value ?? false),
        title: Text(
          t.tr('costs.full_tank'),
          style: const TextStyle(color: Colors.white),
        ),
        activeColor: const Color(0xFFFFB129),
        checkColor: Colors.black,
        tileColor: const Color(0xFF1A2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      const SizedBox(height: 12),
      Text(
        t.tr('costs.trip_distance'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _tripDistanceController,
        decoration: _inputDecoration(t.tr('costs.trip_distance_hint')),
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      const SizedBox(height: 20),
    ];
  }
  
  List<Widget> _buildPeriodFields(AppLocalizations t) {
    return [
      // Zeitraum-Info Container
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151C23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB129).withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, color: Color(0xFFFFB129), size: 20),
                const SizedBox(width: 8),
                Text(
                  t.tr('costs.period_settings'),
                  style: const TextStyle(
                    color: Color(0xFFFFB129),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Start-Datum
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.tr('costs.period_start'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              subtitle: Text(
                _periodStartDate != null 
                    ? DateFormat('dd.MM.yyyy').format(_periodStartDate!)
                    : t.tr('costs.select_date'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: const Icon(Icons.calendar_today, color: Color(0xFFFFB129)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _periodStartDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: Color(0xFFFFB129)),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) {
                  setState(() => _periodStartDate = date);
                }
              },
            ),
            const Divider(color: Colors.white12),
            
            // End-Datum
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.tr('costs.period_end'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              subtitle: Text(
                _periodEndDate != null 
                    ? DateFormat('dd.MM.yyyy').format(_periodEndDate!)
                    : t.tr('costs.select_date'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: const Icon(Icons.calendar_today, color: Color(0xFFFFB129)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _periodEndDate ?? _periodStartDate ?? DateTime.now(),
                  firstDate: _periodStartDate ?? DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: Color(0xFFFFB129)),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) {
                  setState(() => _periodEndDate = date);
                }
              },
            ),
            const Divider(color: Colors.white12),
            
            // Monatlicher Betrag oder Gesamtbetrag
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _isMonthlyAmount 
                    ? t.tr('costs.monthly_amount')
                    : t.tr('costs.total_amount'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: Text(
                _isMonthlyAmount
                    ? (_amountController.text.isNotEmpty 
                        ? t.tr('costs.monthly_amount_hint_dynamic').replaceFirst('{amount}', '${_amountController.text} €')
                        : t.tr('costs.monthly_amount_hint'))
                    : t.tr('costs.total_amount_hint'),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _isMonthlyAmount,
              onChanged: (value) => setState(() => _isMonthlyAmount = value),
              activeColor: const Color(0xFFFFB129),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1A2028),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
