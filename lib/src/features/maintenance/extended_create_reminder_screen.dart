import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../services/maintenance_notification_service.dart';
import '../../services/costs_service.dart';
import '../../services/category_service.dart';
import '../../services/purchase_service.dart';
import '../../models/vehicle_cost.dart';
import '../../models/cost_category.dart';

/// Erweiterter Create/Edit Screen für Wartungen mit allen Features
class ExtendedCreateReminderScreen extends StatefulWidget {
  final MaintenanceReminder? existing;

  const ExtendedCreateReminderScreen({super.key, this.existing});

  @override
  State<ExtendedCreateReminderScreen> createState() => _ExtendedCreateReminderScreenState();
}



class _ExtendedCreateReminderScreenState extends State<ExtendedCreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _workshopNameCtrl = TextEditingController();
  final _workshopAddressCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _mileageAtMaintenanceCtrl = TextEditingController();
  final TextEditingController _dueDateTextCtrl = TextEditingController();

  MaintenanceCategory? _category;
  ReminderType _type = ReminderType.date;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isRecurring = false; // wird UI-seitig ersetzt
  int? _intervalMonths;
  bool _notificationEnabled = true; // steuert Glocke EIN/AUS
  List<int> _notifyOffsetMinutes = [10]; // Liste für Mehrfachauswahl: Standard 10 Min. vorher
  int _customNotifyMinutes = 60; // Für "Angepasst" Option
  int? _repeatEveryDays; // Wiederholen-Intervall in Tagen (null = nicht wiederholen)
  Map<String, dynamic>? _repeatRule;
  bool _loading = false;
  bool _addToCosts = false;
  
  // Laufzeit-Optionen
  String _recurrenceDuration = 'forever'; // 'forever', 'count', 'until'
  int _recurrenceCount = 1;
  DateTime? _recurrenceUntil;

  List<String> _photoKeys = [];
  List<String> _documentKeys = [];
  List<File> _localPhotos = [];
  List<File> _localDocuments = [];

  // Neue Features
  List<String> _customCategories = [];
  String? _customSelectedLabel;
  Map<String, IconData> _customCategoryIcons = {}; // Icon-Mapping für Custom-Categories
  bool _tireSummer = false;
  bool _tireWinter = false;
  Map<String, String> _workshopBook = {};
  final FocusNode _dateFocusNode = FocusNode();
  final TextEditingController _customCategoryCtrl = TextEditingController();
  bool _showCustomCategoryInput = false; // Toggle für Sonstiges-Inputfeld

  @override
  void initState() {
    super.initState();
    _initLocalData();
    if (widget.existing != null) {
      _loadExisting();
    }
  }

  void _openRepeatScreen() {
    final t = AppLocalizations.of(context);
    
    int? tempDays = _repeatEveryDays;
    final Set<int> weekDays = <int>{}; 
    final Set<int> monthDays = <int>{}; // Für Monatstage-Auswahl
    int factor = 1; 
    // Separate Intervalle für jede Option
    int dayInterval = 1;
    int weekInterval = 1;
    int monthInterval = 1;
    int yearInterval = 1;
    bool monthlyByNth = false;
    bool monthlyByDate = false;
    bool monthlyByCustomDays = false;
    bool yearlyByNth = false;
    int selectedMonth = (_dueDate ?? DateTime.now()).month;
    String tempDuration = _recurrenceDuration;
    int tempCount = _recurrenceCount;
    DateTime? tempUntil = _recurrenceUntil;
    
    // Werte aus _repeatRule laden, falls vorhanden
    if (_repeatRule != null) {
      final type = _repeatRule!['type'];
      final interval = _repeatRule!['interval'] ?? 1;
      
      if (type == 'daily') {
        factor = 1;
        dayInterval = interval;
      } else if (type == 'weekly') {
        factor = 7;
        weekInterval = interval;
        final days = _repeatRule!['days'] as List?;
        if (days != null) weekDays.addAll(days.cast<int>());
      } else if (type == 'monthly') {
        factor = 30;
        monthInterval = interval;
        if (_repeatRule!.containsKey('daysOfMonth')) {
          monthlyByCustomDays = true;
          final days = _repeatRule!['daysOfMonth'] as List?;
          if (days != null) monthDays.addAll(days.cast<int>());
        } else if (_repeatRule!.containsKey('nth')) {
          monthlyByNth = true;
        } else {
          monthlyByDate = true;
        }
      } else if (type == 'yearly') {
        factor = 365;
        yearInterval = interval;
        selectedMonth = _repeatRule!['month'] ?? selectedMonth;
        if (_repeatRule!.containsKey('nth')) {
          yearlyByNth = true;
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        
        // factor wurde bereits aus _repeatRule gesetzt, falls vorhanden
        // Falls nicht, versuche aus tempDays zu berechnen
        if (_repeatRule == null && tempDays != null && tempDays! > 0) {
          if (tempDays! % 365 == 0) { 
            factor = 365; 
            yearInterval = tempDays! ~/ 365;
          }
          else if (tempDays! % 30 == 0) { 
            factor = 30; 
            monthInterval = tempDays! ~/ 30;
          }
          else if (tempDays! % 7 == 0) { 
            factor = 7; 
            weekInterval = tempDays! ~/ 7;
          }
          else { 
            factor = 1; 
            dayInterval = tempDays!;
          }
        }
        
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return GestureDetector(
              onTap: () {
                // Tastatur schließen bei Klick außerhalb
                FocusScope.of(ctx).unfocus();
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36, 
                          height: 4, 
                          decoration: BoxDecoration(
                            color: Colors.white24, 
                            borderRadius: BorderRadius.circular(2)
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              // Auto-Save beim Schließen
                              setState(() {
                                _repeatEveryDays = tempDays;
                                _recurrenceDuration = tempDuration;
                                _recurrenceCount = tempCount;
                                _recurrenceUntil = tempUntil;
                                
                                // Baue RecurrenceRule
                                if (tempDays == null || tempDays! <= 0) {
                                  _repeatRule = null;
                                } else if (factor == 1) {
                                  _repeatRule = {'type': 'daily', 'interval': dayInterval};
                                } else if (factor == 7) {
                                  _repeatRule = {'type': 'weekly', 'interval': weekInterval, 'days': weekDays.toList()};
                                } else if (factor == 30) {
                                  final base = _dueDate ?? DateTime.now();
                                  final nth = ((base.day - 1) ~/ 7) + 1;
                                  if (monthlyByCustomDays && monthDays.isNotEmpty) {
                                    _repeatRule = {'type': 'monthly', 'interval': monthInterval, 'daysOfMonth': monthDays.toList()};
                                  } else if (monthlyByNth) {
                                    _repeatRule = {'type': 'monthly', 'interval': monthInterval, 'nth': nth, 'weekday': base.weekday};
                                  } else {
                                    _repeatRule = {'type': 'monthly', 'interval': monthInterval, 'dayOfMonth': base.day};
                                  }
                                } else if (factor == 365) {
                                  final baseDate = _dueDate ?? DateTime.now();
                                  final base = DateTime(baseDate.year, selectedMonth, baseDate.day);
                                  final nth = ((base.day - 1) ~/ 7) + 1;
                                  _repeatRule = yearlyByNth
                                      ? {'type': 'yearly', 'interval': yearInterval, 'month': selectedMonth, 'nth': nth, 'weekday': base.weekday}
                                      : {'type': 'yearly', 'interval': yearInterval, 'month': selectedMonth, 'day': base.day};
                                }
                                
                                // Laufzeit-Info zur Rule hinzufügen
                                if (_repeatRule != null) {
                                  if (tempDuration == 'count') {
                                    _repeatRule!['count'] = tempCount;
                                  } else if (tempDuration == 'until' && tempUntil != null) {
                                    _repeatRule!['until'] = tempUntil!.toIso8601String();
                                  }
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.maintenance_repeat_title, 
                            style: const TextStyle(
                              fontWeight: FontWeight.w700, 
                              fontSize: 20,
                              color: Colors.white,
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Nicht wiederholen
                      _buildRepeatOption(
                        value: null,
                        groupValue: tempDays,
                        label: t.maintenance_repeat_none,
                        onTap: () => setSt(() { tempDays = null; factor = 1; }),
                      ),
                      
                      // Jeden/Alle X Tag(e)
                      Row(
                        children: [
                          Radio<int>(
                            value: 1,
                            groupValue: factor == 1 && tempDays != null ? factor : null,
                            onChanged: (_) => setSt(() { factor = 1; tempDays = dayInterval * 1; }),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dayInterval == 1 ? t.tr('repeat.every_singular_day') : t.tr('repeat.every_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white54),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                              controller: TextEditingController(text: dayInterval.toString())..selection = TextSelection.fromPosition(TextPosition(offset: dayInterval.toString().length)),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setSt(() {
                                    dayInterval = parsed;
                                    tempDays = dayInterval * 1;
                                  });
                                }
                              },
                              onTap: () => setSt(() { factor = 1; tempDays = dayInterval * 1; }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dayInterval == 1 ? t.tr('repeat.day_singular') : t.tr('repeat.day_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      
                      // Jede/Alle X Woche(n)
                      Row(
                        children: [
                          Radio<int>(
                            value: 7,
                            groupValue: factor == 7 && tempDays != null ? factor : null,
                            onChanged: (_) => setSt(() { factor = 7; tempDays = weekInterval * 7; }),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            weekInterval == 1 ? t.tr('repeat.every_singular_week') : t.tr('repeat.every_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white54),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                              controller: TextEditingController(text: weekInterval.toString())..selection = TextSelection.fromPosition(TextPosition(offset: weekInterval.toString().length)),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setSt(() {
                                    weekInterval = parsed;
                                    tempDays = weekInterval * 7;
                                  });
                                }
                              },
                              onTap: () => setSt(() { factor = 7; tempDays = weekInterval * 7; }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            weekInterval == 1 ? t.tr('repeat.week_singular') : t.tr('repeat.week_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      
                      // Wochentage-Auswahl
                      if (factor == 7) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 48, top: 12, bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(7, (i) {
                              final idx = i + 1;
                              final labels = [
                                t.weekday_mo, t.weekday_tu, t.weekday_we,
                                t.weekday_th, t.weekday_fr, t.weekday_sa, t.weekday_su,
                              ];
                              final selected = weekDays.contains(idx);
                              return FilterChip(
                                label: Text(labels[i]),
                                selected: selected,
                                backgroundColor: const Color(0xFF1F2933),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : Colors.white70,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                onSelected: (_) => setSt(() {
                                  if (selected) weekDays.remove(idx);
                                  else weekDays.add(idx);
                                }),
                              );
                            }),
                          ),
                        ),
                      ],
                      
                      // Jeder/Alle X Monat(e)
                      Row(
                        children: [
                          Radio<int>(
                            value: 30,
                            groupValue: factor == 30 && tempDays != null ? factor : null,
                            onChanged: (_) => setSt(() { factor = 30; tempDays = monthInterval * 30; }),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            monthInterval == 1 ? t.tr('repeat.every_singular_month') : t.tr('repeat.every_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white54),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                              controller: TextEditingController(text: monthInterval.toString())..selection = TextSelection.fromPosition(TextPosition(offset: monthInterval.toString().length)),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setSt(() {
                                    monthInterval = parsed;
                                    tempDays = monthInterval * 30;
                                  });
                                }
                              },
                              onTap: () => setSt(() { factor = 30; tempDays = monthInterval * 30; }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            monthInterval == 1 ? t.tr('repeat.month_singular') : t.tr('repeat.month_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      
                      // Monats-Optionen (zentriert)
                      if (factor == 30) ...[
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSecondaryButton(
                                  t.tr('repeat.on_day_repeat').replaceAll('{day}', '${(_dueDate ?? DateTime.now()).day}'),
                                  isSelected: monthlyByDate && !monthlyByNth && !monthlyByCustomDays,
                                  onTap: () => setSt(() { monthlyByDate = true; monthlyByNth = false; monthlyByCustomDays = false; }),
                                ),
                                const SizedBox(height: 8),
                                _buildSecondaryButton(
                                  t.tr('repeat.on_nth_weekday_repeat').replaceAll('{nth}', '${(((_dueDate ?? DateTime.now()).day - 1) ~/ 7) + 1}').replaceAll('{weekday}', DateFormat.EEEE(Localizations.localeOf(context).languageCode).format(_dueDate ?? DateTime.now())),
                                  isSelected: monthlyByNth && !monthlyByDate && !monthlyByCustomDays,
                                  onTap: () => setSt(() { monthlyByNth = true; monthlyByDate = false; monthlyByCustomDays = false; }),
                                ),
                                const SizedBox(height: 8),
                                _buildSecondaryButton(
                                  t.tr('repeat.select_dates'),
                                  isSelected: monthlyByCustomDays,
                                  onTap: () => setSt(() { monthlyByDate = false; monthlyByNth = false; monthlyByCustomDays = true; }),
                                ),
                              ...(monthlyByCustomDays ? [
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(31, (i) {
                                    final day = i + 1;
                                    final isSelected = monthDays.contains(day);
                                    return GestureDetector(
                                      onTap: () => setSt(() {
                                        if (isSelected) monthDays.remove(day);
                                        else monthDays.add(day);
                                      }),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? Colors.blue : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected ? Colors.blue : Colors.white30,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$day',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ] : []),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      // Jedes/Alle X Jahr(e)
                      Row(
                        children: [
                          Radio<int>(
                            value: 365,
                            groupValue: factor == 365 && tempDays != null ? factor : null,
                            onChanged: (_) => setSt(() { factor = 365; tempDays = yearInterval * 365; }),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            yearInterval == 1 ? t.tr('repeat.every_singular_year') : t.tr('repeat.every_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white54),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                              controller: TextEditingController(text: yearInterval.toString())..selection = TextSelection.fromPosition(TextPosition(offset: yearInterval.toString().length)),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setSt(() {
                                    yearInterval = parsed;
                                    tempDays = yearInterval * 365;
                                  });
                                }
                              },
                              onTap: () => setSt(() { factor = 365; tempDays = yearInterval * 365; }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            yearInterval == 1 ? t.tr('repeat.year_singular') : t.tr('repeat.year_plural'),
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      
                      // Jahres-Optionen (zentriert)
                      if (factor == 365) ...[
                      Center(
                      child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSecondaryButton(
                        t.tr('repeat.in_month_on_day').replaceAll('{month}', DateFormat.MMM(Localizations.localeOf(context).languageCode).format(DateTime(2000, selectedMonth, 1))).replaceAll('{day}', '${(_dueDate ?? DateTime.now()).day}'),
                        isSelected: !yearlyByNth,
                        onTap: () => setSt(() => yearlyByNth = false),
                        ),
                        const SizedBox(height: 8),
                        _buildSecondaryButton(
                        t.tr('repeat.on_nth_weekday_in_month').replaceAll('{nth}', '${(((_dueDate ?? DateTime.now()).day - 1) ~/ 7) + 1}').replaceAll('{weekday}', DateFormat.E(Localizations.localeOf(context).languageCode).format(_dueDate ?? DateTime.now())).replaceAll('{month}', DateFormat.MMM(Localizations.localeOf(context).languageCode).format(DateTime(2000, selectedMonth, 1))),
                        isSelected: yearlyByNth,
                        onTap: () => setSt(() => yearlyByNth = true),
                        ),
                        const SizedBox(height: 12),
                        // Monatspicker
                        Container(
                        height: 120,
                        decoration: BoxDecoration(
                        color: const Color(0xFF1F2933),
                        borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoPicker(
                        backgroundColor: Colors.transparent,
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                        initialItem: selectedMonth - 1
                        ),
                        onSelectedItemChanged: (i) {
                        setSt(() => selectedMonth = i + 1);
                        },
                        children: List.generate(12, (i) {
                        final month = DateTime(2000, i + 1, 1);
                        final label = DateFormat.MMMM(Localizations.localeOf(context).languageCode).format(month);
                        return Center(
                        child: Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        );
                        }),
                        ),
                        ),
                        ],
                      ),
                      ),
                      ),
                      ],
                      
                      // Laufzeit-Sektion (nur wenn Wiederholung aktiviert)
                      if (tempDays != null && tempDays! > 0) ...[
                        const SizedBox(height: 24),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'Laufzeit',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Für immer
                        _buildRepeatOption(
                          value: 'forever',
                          groupValue: tempDuration,
                          label: 'Für immer',
                          onTap: () => setSt(() => tempDuration = 'forever'),
                        ),
                        
                        // Bestimmte Anzahl
                        _buildRepeatOption(
                          value: 'count',
                          groupValue: tempDuration,
                          label: 'Bestimmte Anzahl',
                          onTap: () => setSt(() => tempDuration = 'count'),
                        ),
                        
                        if (tempDuration == 'count') ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F2933),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Anzahl',
                                        hintStyle: TextStyle(color: Colors.white54),
                                      ),
                                      controller: TextEditingController(text: tempCount.toString())..selection = TextSelection.fromPosition(TextPosition(offset: tempCount.toString().length)),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val);
                                        if (parsed != null && parsed > 0) {
                                          tempCount = parsed;
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Bis
                        _buildRepeatOption(
                          value: 'until',
                          groupValue: tempDuration,
                          label: 'Bis',
                          onTap: () => setSt(() => tempDuration = 'until'),
                        ),
                        
                        if (tempDuration == 'until') ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                            child: OutlinedButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: tempUntil ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Colors.white,
                                          surface: Color(0xFF11161C),
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setSt(() => tempUntil = date);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                backgroundColor: const Color(0xFF1F2933),
                              ),
                              child: Text(
                                tempUntil != null
                                    ? DateFormat('dd.MM.yyyy').format(tempUntil!)
                                    : 'Datum wählen',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
            );
          },
        );
      },
    ).then((_) {
      // Auto-Save beim Dismiss (außerhalb klicken)
      setState(() {
        _repeatEveryDays = tempDays;
        _recurrenceDuration = tempDuration;
        _recurrenceCount = tempCount;
        _recurrenceUntil = tempUntil;
        
        // Baue RecurrenceRule
        if (tempDays == null || tempDays! <= 0) {
          _repeatRule = null;
        } else if (factor == 1) {
          _repeatRule = {'type': 'daily', 'interval': dayInterval};
        } else if (factor == 7) {
          _repeatRule = {'type': 'weekly', 'interval': weekInterval, 'days': weekDays.toList()};
        } else if (factor == 30) {
          final base = _dueDate ?? DateTime.now();
          final nth = ((base.day - 1) ~/ 7) + 1;
          if (monthlyByCustomDays && monthDays.isNotEmpty) {
            _repeatRule = {'type': 'monthly', 'interval': monthInterval, 'daysOfMonth': monthDays.toList()};
          } else if (monthlyByNth) {
            _repeatRule = {'type': 'monthly', 'interval': monthInterval, 'nth': nth, 'weekday': base.weekday};
          } else {
            _repeatRule = {'type': 'monthly', 'interval': monthInterval, 'dayOfMonth': base.day};
          }
        } else if (factor == 365) {
          final baseDate = _dueDate ?? DateTime.now();
          final base = DateTime(baseDate.year, selectedMonth, baseDate.day);
          final nth = ((base.day - 1) ~/ 7) + 1;
          _repeatRule = yearlyByNth
              ? {'type': 'yearly', 'interval': yearInterval, 'month': selectedMonth, 'nth': nth, 'weekday': base.weekday}
              : {'type': 'yearly', 'interval': yearInterval, 'month': selectedMonth, 'day': base.day};
        }
        
        // Laufzeit-Info zur Rule hinzufügen
        if (_repeatRule != null) {
          if (tempDuration == 'count') {
            _repeatRule!['count'] = tempCount;
          } else if (tempDuration == 'until' && tempUntil != null) {
            _repeatRule!['until'] = tempUntil!.toIso8601String();
          }
        }
      });
    });
  }

  String _repeatPreviewLabel(AppLocalizations t) {
    if (_repeatEveryDays == null || _repeatEveryDays! <= 0) return t.maintenance_repeat_none;
    
    if (_repeatRule == null) {
      return 'Alle ${_repeatEveryDays} Tage';
    }
    
    final type = _repeatRule!['type'];
    final interval = _repeatRule!['interval'] ?? 1;
    
    if (type == 'daily') {
      return interval == 1 ? t.tr('repeat.every_day') : t.tr('recurrence.every_x_days').replaceAll('{count}', '$interval');
    } else if (type == 'weekly') {
      final days = _repeatRule!['days'] as List?;
      final weekdayNamesShort = [
        t.tr('weekday.monday'), t.tr('weekday.tuesday'), t.tr('weekday.wednesday'),
        t.tr('weekday.thursday'), t.tr('weekday.friday'), t.tr('weekday.saturday'), t.tr('weekday.sunday')
      ];
      if (days != null && days.isNotEmpty) {
        if (interval == 1 && days.length == 1) {
          final weekdayName = weekdayNamesShort[(days[0] as int) - 1];
          return '${t.tr('repeat.every_day').replaceAll(t.tr('repeat.day'), weekdayName)}';
        } else {
          final weekdayNamesAbbr = [
            t.tr('weekday.monday_short'), t.tr('weekday.tuesday_short'), t.tr('weekday.wednesday_short'),
            t.tr('weekday.thursday_short'), t.tr('weekday.friday_short'), t.tr('weekday.saturday_short'), t.tr('weekday.sunday_short')
          ];
          final dayLabels = days.map((d) => weekdayNamesAbbr[(d as int) - 1]).join(', ');
          return interval == 1 
            ? t.tr('recurrence.every_week_on').replaceAll('{days}', dayLabels)
            : t.tr('recurrence.every_x_weeks_on').replaceAll('{count}', '$interval').replaceAll('{days}', dayLabels);
        }
      }
      return interval == 1 ? t.tr('repeat.every_week') : t.tr('recurrence.every_x_weeks_on').replaceAll('{count}', '$interval').replaceAll(' am {days}', '');
    } else if (type == 'monthly') {
      final daysOfMonth = _repeatRule!['daysOfMonth'] as List?;
      if (daysOfMonth != null && daysOfMonth.isNotEmpty) {
        final dayList = daysOfMonth.map((d) => '$d.').join(', ');
        return interval == 1 
          ? t.tr('recurrence.every_month_on_day').replaceAll('{day}', dayList)
          : t.tr('recurrence.every_x_months_on_day').replaceAll('{count}', '$interval').replaceAll('{day}', dayList);
      }
      final dayOfMonth = _repeatRule!['dayOfMonth'];
      final nth = _repeatRule!['nth'];
      if (dayOfMonth != null) {
        return interval == 1 
          ? t.tr('recurrence.every_month_on_day').replaceAll('{day}', '$dayOfMonth')
          : t.tr('recurrence.every_x_months_on_day').replaceAll('{count}', '$interval').replaceAll('{day}', '$dayOfMonth');
      } else if (nth != null) {
        final weekday = _repeatRule!['weekday'];
        final weekdayNames = [
          t.tr('weekday.monday'), t.tr('weekday.tuesday'), t.tr('weekday.wednesday'),
          t.tr('weekday.thursday'), t.tr('weekday.friday'), t.tr('weekday.saturday'), t.tr('weekday.sunday')
        ];
        final weekdayName = weekdayNames[(weekday as int) - 1];
        return interval == 1 
          ? t.tr('recurrence.every_month_on_weekday').replaceAll('{nth}', '$nth').replaceAll('{weekday}', weekdayName)
          : t.tr('recurrence.every_x_months_on_weekday').replaceAll('{count}', '$interval').replaceAll('{nth}', '$nth').replaceAll('{weekday}', weekdayName);
      }
      return interval == 1 ? t.tr('repeat.every_month') : t.tr('recurrence.every_x_months_on_day').replaceAll('{count}', '$interval').replaceAll(' am {day}.', '');
    } else if (type == 'yearly') {
      final month = _repeatRule!['month'];
      final day = _repeatRule!['day'];
      final nth = _repeatRule!['nth'];
      final monthKeys = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      final monthName = month != null ? t.tr('month_short.${monthKeys[(month as int) - 1]}') : '';
      
      if (day != null) {
        return interval == 1 
          ? t.tr('recurrence.every_year_on').replaceAll('{day}', '$day').replaceAll('{month}', monthName)
          : t.tr('recurrence.every_x_years_on').replaceAll('{count}', '$interval').replaceAll('{day}', '$day').replaceAll('{month}', monthName);
      } else if (nth != null) {
        final weekday = _repeatRule!['weekday'];
        final weekdayNames = [
          t.tr('weekday.monday'), t.tr('weekday.tuesday'), t.tr('weekday.wednesday'),
          t.tr('weekday.thursday'), t.tr('weekday.friday'), t.tr('weekday.saturday'), t.tr('weekday.sunday')
        ];
        final weekdayName = weekdayNames[(weekday as int) - 1];
        return interval == 1 
          ? t.tr('recurrence.every_year_on_weekday').replaceAll('{nth}', '$nth').replaceAll('{weekday}', weekdayName).replaceAll('{month}', monthName)
          : t.tr('recurrence.every_x_years_on_weekday').replaceAll('{count}', '$interval').replaceAll('{nth}', '$nth').replaceAll('{weekday}', weekdayName).replaceAll('{month}', monthName);
      }
      
      return interval == 1 
        ? t.tr('recurrence.every_year_on').replaceAll(' {day}.', '').replaceAll('{month}', monthName)
        : t.tr('recurrence.every_x_years_on').replaceAll('{count}', '$interval').replaceAll(' {day}.', '').replaceAll('{month}', monthName);
    }
    
    return t.tr('recurrence.every_x_days').replaceAll('{count}', '$_repeatEveryDays');
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              surface: Color(0xFF11161C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      // Nach Datum-Auswahl: Uhrzeit-Picker anzeigen
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: _dueTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.white,
                surface: Color(0xFF11161C),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (!mounted) return;
      setState(() {
        _dueDate = DateTime(date.year, date.month, date.day);
        if (time != null) {
          _dueTime = time;
          _dueDateTextCtrl.text = '${DateFormat('dd.MM.yyyy').format(_dueDate!)} ${time.format(context)}';
        } else {
          _dueDateTextCtrl.text = DateFormat('dd.MM.yyyy').format(_dueDate!);
        }
      });
    }
  }

  Future<void> _initLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    _customCategories = prefs.getStringList('custom_categories') ?? [];
    
    // Lade Custom-Icons
    final iconsRaw = prefs.getString('custom_category_icons');
    if (iconsRaw != null && iconsRaw.isNotEmpty) {
      try {
        final map = json.decode(iconsRaw) as Map<String, dynamic>;
        _customCategoryIcons = map.map((k, v) => MapEntry(k, _iconFromCodePoint(v as int)));
      } catch (_) {}
    }
    
    final raw = prefs.getString('workshops_book');
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        _workshopBook = map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  IconData _iconFromCodePoint(int codePoint) {
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  Future<void> _addCustomCategory(String label) async {
    if (label.isEmpty || _customCategories.contains(label)) return;
    final prefs = await SharedPreferences.getInstance();
    _customCategories = [..._customCategories, label];
    await prefs.setStringList('custom_categories', _customCategories);
    
    // Weise ein Icon zu (zyklisch durch 3 Icons)
    final availableIcons = [Icons.star, Icons.build, Icons.settings];
    final iconIndex = (_customCategories.length - 1) % availableIcons.length;
    _customCategoryIcons[label] = availableIcons[iconIndex];
    
    // Speichere Icon-Mapping
    final iconMap = _customCategoryIcons.map((k, v) => MapEntry(k, v.codePoint));
    await prefs.setString('custom_category_icons', json.encode(iconMap));
    
    // Verstecke Inputfeld, leere Feld, schließe Tastatur
    _customCategoryCtrl.clear();
    _showCustomCategoryInput = false;
    FocusScope.of(context).unfocus();
    
    if (mounted) setState(() {});
  }

  Future<void> _removeCustomCategory(String label) async {
    final prefs = await SharedPreferences.getInstance();
    _customCategories = _customCategories.where((e) => e != label).toList();
    await prefs.setStringList('custom_categories', _customCategories);
    
    // Entferne Icon-Mapping
    _customCategoryIcons.remove(label);
    final iconMap = _customCategoryIcons.map((k, v) => MapEntry(k, v.codePoint));
    await prefs.setString('custom_category_icons', json.encode(iconMap));
    
    if (_customSelectedLabel == label) _customSelectedLabel = null;
    if (mounted) setState(() {});
  }

  Future<void> _rememberWorkshop(String name, String address) async {
    if (name.isEmpty || address.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _workshopBook[name] = address;
    await prefs.setString('workshops_book', json.encode(_workshopBook));
  }

  Future<void> _showDeleteCustomCategoryDialog(String label) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151C23),
        title: Text(t.maintenance_custom_category_delete_title, style: const TextStyle(color: Colors.white)),
        content: Text(
          t.maintenance_custom_category_delete_message.replaceAll('{label}', label),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.maintenance_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.maintenance_delete),
          ),
        ],
      ),
    );
    if (ok == true) await _removeCustomCategory(label);
  }

  void _loadExisting() {
    final e = widget.existing!;
    _titleCtrl.text = e.title;
    _descCtrl.text = e.description ?? '';
    _category = e.category;
    _type = e.reminderType;
    _dueDate = e.dueDate;
    if (_dueDate != null) {
      _dueDateTextCtrl.text = DateFormat('dd.MM.yyyy').format(_dueDate!);
    }
    if (e.dueMileage != null) _mileageCtrl.text = e.dueMileage.toString();
    if (e.mileageAtMaintenance != null) {
      _mileageAtMaintenanceCtrl.text = e.mileageAtMaintenance.toString();
    }
    _workshopNameCtrl.text = e.workshopName ?? '';
    _workshopAddressCtrl.text = e.workshopAddress ?? '';
    if (e.cost != null) _costCtrl.text = e.cost.toString();
    
    // Notizen laden und Meta-Tags parsen
    String rawNotes = e.notes ?? '';
    final metaRegex = RegExp(r'\[meta:(.*?)\]');
    final metaMatch = metaRegex.firstMatch(rawNotes);
    if (metaMatch != null) {
      // Meta-Tags parsen
      final metaContent = metaMatch.group(1) ?? '';
      final metaParts = metaContent.split(',');
      for (final part in metaParts) {
        if (part == 'summer') _tireSummer = true;
        else if (part == 'winter') _tireWinter = true;
        else if (part.startsWith('custom:')) {
          _customSelectedLabel = part.substring(7);
        }
      }
      // Meta-Zeile aus Notizen entfernen
      rawNotes = rawNotes.replaceAll(metaRegex, '').trim();
    }
    _notesCtrl.text = rawNotes;
    
    _isRecurring = e.isRecurring;
    _notificationEnabled = e.notificationEnabled;
    _notifyOffsetMinutes = [e.notifyOffsetMinutes];
    _repeatEveryDays = e.isRecurring ? e.recurrenceIntervalDays : null;
    _repeatRule = e.recurrenceRule;
    _photoKeys = e.photos.toList();
    _documentKeys = e.documents.toList();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _localPhotos.add(File(picked.path)));
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;
    setState(() => _localDocuments.add(File(result.files.single.path!)));
  }

  /// Kombiniert _dueDate und _dueTime zu einem DateTime
  /// Erstellt das DateTime in lokaler Zeit und konvertiert zu UTC für Supabase
  DateTime? _getCombinedDateTime() {
    if (_dueDate == null) return null;
    
    // Erstelle DateTime in lokaler Zeit
    final localDateTime = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime?.hour ?? 0,
      _dueTime?.minute ?? 0,
    );
    
    // Konvertiere zu UTC für Speicherung in Supabase
    // Wenn User 10:23 lokal eingibt, wird 09:23 UTC gespeichert (bei UTC+1)
    return localDateTime.toUtc();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final svc = MaintenanceService(Supabase.instance.client);

      // Upload neue Fotos
      for (var photo in _localPhotos) {
        final key = await svc.uploadPhoto(photo.path);
        if (key != null) _photoKeys.add(key);
      }

      // Upload neue Dokumente
      for (var doc in _localDocuments) {
        final key = await svc.uploadDocument(doc.path);
        if (key != null) _documentKeys.add(key);
      }

      // Meta-Tags für Reifen und Custom-Categories
      String effectiveNotes = _notesCtrl.text.trim();
      final extras = <String>[];
      if (_category == MaintenanceCategory.tireChange) {
        if (_tireSummer) extras.add('summer');
        if (_tireWinter) extras.add('winter');
      }
      if (_customSelectedLabel != null && _customSelectedLabel!.isNotEmpty) {
        extras.add('custom:$_customSelectedLabel');
      }
      if (extras.isNotEmpty) {
        final tag = '[meta:${extras.join(',')}]';
        effectiveNotes = effectiveNotes.isEmpty ? tag : '$effectiveNotes\n$tag';
      }

      String? savedReminderId;

      if (widget.existing == null) {
        _notifyOffsetMinutes.sort();

        // Neu erstellen
        final created = await svc.createReminder(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: _category,
          reminderType: _type,
          dueDate: _type == ReminderType.date ? _getCombinedDateTime() : null,
          dueMileage: _type == ReminderType.mileage && _mileageCtrl.text.isNotEmpty
              ? int.tryParse(_mileageCtrl.text)
              : null,
          mileageAtMaintenance: _mileageAtMaintenanceCtrl.text.isNotEmpty
              ? int.tryParse(_mileageAtMaintenanceCtrl.text)
              : null,
          workshopName: _workshopNameCtrl.text.trim().isEmpty ? null : _workshopNameCtrl.text.trim(),
          workshopAddress: _workshopAddressCtrl.text.trim().isEmpty ? null : _workshopAddressCtrl.text.trim(),
          cost: _costCtrl.text.isNotEmpty ? double.tryParse(_costCtrl.text) : null,
          notes: effectiveNotes.isEmpty ? null : effectiveNotes,
          photos: _photoKeys.isEmpty ? null : _photoKeys,
          documents: _documentKeys.isEmpty ? null : _documentKeys,
          isRecurring: _repeatEveryDays != null && _repeatEveryDays! > 0,
          recurrenceIntervalDays: _repeatEveryDays,
          recurrenceRule: _repeatRule,
          notificationEnabled: _notificationEnabled,
          notifyOffsetMinutes: _notifyOffsetMinutes.isEmpty ? 10 : _notifyOffsetMinutes.first,
        );
        savedReminderId = created.id;
        
        // Notification wurde bereits von createReminder für den ersten Offset geplant
        // Plane zusätzliche Benachrichtigungen für weitere Offsets (falls mehrere gewählt)
        if (_notificationEnabled && _notifyOffsetMinutes.length > 1) {
          for (int i = 1; i < _notifyOffsetMinutes.length; i++) {
            try {
              await MaintenanceNotificationService.scheduleMaintenanceReminder(
                created,
                offsetMinutes: _notifyOffsetMinutes[i],
              );
            } catch (e) {
              print('Fehler beim Planen zusätzlicher Notification (${_notifyOffsetMinutes[i]} Min): $e');
            }
          }
        }
      } else {
        // Aktualisieren (updateReminder plant bereits die Notification intern)
        _notifyOffsetMinutes.sort();
        savedReminderId = widget.existing!.id;

        await svc.updateReminder(
          id: widget.existing!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: _category,
          dueDate: _type == ReminderType.date ? _getCombinedDateTime() : null,
          dueMileage: _type == ReminderType.mileage && _mileageCtrl.text.isNotEmpty
              ? int.tryParse(_mileageCtrl.text)
              : null,
          mileageAtMaintenance: _mileageAtMaintenanceCtrl.text.isNotEmpty
              ? int.tryParse(_mileageAtMaintenanceCtrl.text)
              : null,
          workshopName: _workshopNameCtrl.text.trim().isEmpty ? null : _workshopNameCtrl.text.trim(),
          workshopAddress: _workshopAddressCtrl.text.trim().isEmpty ? null : _workshopAddressCtrl.text.trim(),
          cost: _costCtrl.text.isNotEmpty ? double.tryParse(_costCtrl.text) : null,
          notes: effectiveNotes.isEmpty ? null : effectiveNotes,
          photos: _photoKeys.isEmpty ? null : _photoKeys,
          documents: _documentKeys.isEmpty ? null : _documentKeys,
          isRecurring: _repeatEveryDays != null && _repeatEveryDays! > 0,
          recurrenceIntervalDays: _repeatEveryDays,
          recurrenceRule: _repeatRule,
          notificationEnabled: _notificationEnabled,
          notifyOffsetMinutes: _notifyOffsetMinutes.isEmpty ? 10 : _notifyOffsetMinutes.first,
        );
        
        // Plane zusätzliche Benachrichtigungen für weitere Offsets (falls mehrere gewählt)
        if (_notificationEnabled && _notifyOffsetMinutes.length > 1) {
          // Hole aktualisierte Wartung
          final updated = await svc.getReminder(widget.existing!.id);
          if (updated != null) {
            for (int i = 1; i < _notifyOffsetMinutes.length; i++) {
              try {
                await MaintenanceNotificationService.scheduleMaintenanceReminder(
                  updated,
                  offsetMinutes: _notifyOffsetMinutes[i],
                );
              } catch (e) {
                print('Fehler beim Planen zusätzlicher Notification (${_notifyOffsetMinutes[i]} Min): $e');
              }
            }
          }
        }
      }

      // Werkstatt merken
      await _rememberWorkshop(_workshopNameCtrl.text.trim(), _workshopAddressCtrl.text.trim());

      // ----------------------------------------------------------
      // NEU: Kosten in Fahrzeugkosten übernehmen
      // ----------------------------------------------------------
      if (_addToCosts && _costCtrl.text.isNotEmpty) {
        final amount = double.tryParse(_costCtrl.text);
        if (amount != null && amount > 0 && savedReminderId != null) {
          final costsService = CostsService();
          final catService = CategoryService();
          final t = AppLocalizations.of(context);
          
          // 1. Kategorie finden oder erstellen
          String categoryId = '';
          
          // Fall A: Custom Maintenance Category (Sonstiges + Label)
          if (_category == MaintenanceCategory.other && _customSelectedLabel != null) {
             final label = _customSelectedLabel!;
             // Prüfe ob Custom Category existiert
             final allCats = await catService.fetchCustomCategories();
             final existing = allCats.firstWhere(
               (c) => c.name.toLowerCase() == label.toLowerCase(),
               orElse: () => const CostCategory(id: '', name: '', iconName: '', colorHex: ''),
             );
             
             if (existing.id.isNotEmpty) {
               categoryId = existing.id;
             } else {
               // Erstellen
               // Icon bestimmen basierend auf dem zugewiesenen Icon
               String iconName = 'more_horiz';
               if (_customCategoryIcons.containsKey(label)) {
                 final iconData = _customCategoryIcons[label]!;
                 // Reverse map try (limited) or default
                 if (iconData == Icons.star) iconName = 'star';
                 else if (iconData == Icons.build) iconName = 'build';
                 else if (iconData == Icons.settings) iconName = 'settings';
               }
               
               final newCat = await catService.createCustomCategory(
                name: label,
                iconName: iconName,
                colorHex: '#90A4AE',
              );
              
              // Falls Erstellung fehlschlägt (z.B. Duplikat), nochmals suchen
              if (newCat == null || newCat.id.isEmpty) {
                final retryList = await catService.fetchCustomCategories();
                final retryMatch = retryList.firstWhere(
                  (c) => c.name.toLowerCase() == label.toLowerCase(),
                  orElse: () => const CostCategory(id: '', name: '', iconName: '', colorHex: ''),
                );
                categoryId = retryMatch.id;
              } else {
                categoryId = newCat.id;
              }
             }
          } else {
             // Fall B: Standard Maintenance Category
             // Label z.B. "Bremsen" (lokalisiert)
             final label = _getCategoryLabel(t, _category ?? MaintenanceCategory.other);
             
             // Suche nach Kategorie mit diesem Namen (System oder Custom)
             // ACHTUNG: System-Kategorien haben oft englische Namen in DB, aber wir suchen hier nach lokalisiertem Namen?
             // Besser: Wir suchen zuerst nach System-Kategorien die passen KÖNNTEN, aber wenn User "Bremsen" will, 
             // und System nur "Maintenance" hat, müssen wir Custom "Bremsen" erstellen.
             
             final allCats = await catService.fetchAllCategories();
             final existing = allCats.firstWhere(
               (c) => c.name.toLowerCase() == label.toLowerCase(),
               orElse: () => const CostCategory(id: '', name: '', iconName: '', colorHex: ''),
             );
             
             if (existing.id.isNotEmpty) {
               categoryId = existing.id;
             } else {
               // Erstellen als Custom Category damit Name & Icon passen
               final iconName = _getCategoryIconName(_category ?? MaintenanceCategory.other);
               final color = _getCategoryColor(_category ?? MaintenanceCategory.other);
               final colorHex = '#${color.value.toRadixString(16).substring(2)}';
               
               final newCat = await catService.createCustomCategory(
                 name: label,
                 iconName: iconName,
                 colorHex: colorHex,
               );
               
               // Falls Erstellung fehlschlägt (z.B. Duplikat), nochmals suchen
               if (newCat == null || newCat.id.isEmpty) {
                 final retryList = await catService.fetchAllCategories();
                 final retryMatch = retryList.firstWhere(
                   (c) => c.name.toLowerCase() == label.toLowerCase(),
                   orElse: () => const CostCategory(id: '', name: '', iconName: '', colorHex: ''),
                 );
                 categoryId = retryMatch.id;
               } else {
                 categoryId = newCat.id;
               }
             }
          }
          
          if (categoryId.isNotEmpty) {
            await costsService.createCost(VehicleCost(
              id: '', // DB gen
              userId: '', // Service sets it
              categoryId: categoryId,
              title: _titleCtrl.text.isEmpty ? _getCategoryLabel(t, _category ?? MaintenanceCategory.other) : _titleCtrl.text,
              amount: amount,
              date: _dueDate ?? DateTime.now(),
              mileage: _mileageAtMaintenanceCtrl.text.isNotEmpty ? int.tryParse(_mileageAtMaintenanceCtrl.text) : null,
              notes: effectiveNotes.isEmpty ? null : effectiveNotes,
              maintenanceReminderId: savedReminderId,
            ));
          }
        }
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _offsetLabel(AppLocalizations t, int minutes) {
    if (minutes == 0) return t.maintenance_reminder_at_event;
    if (minutes == 10) return t.maintenance_reminder_10m;
    if (minutes == 60) return t.maintenance_reminder_1h;
    if (minutes == 24 * 60) return t.maintenance_reminder_1d;
    
    // Bessere Formatierung für große Werte
    if (minutes >= 1440) {
      final days = (minutes / 1440).round();
      return days == 1 
        ? t.tr('reminder.day_before').replaceAll('{count}', '1')
        : t.tr('reminder.days_before').replaceAll('{count}', '$days');
    } else if (minutes >= 60) {
      final hours = (minutes / 60).round();
      return t.tr('reminder.hours_before').replaceAll('{count}', '$hours');
    }
    return t.tr('reminder.minutes_before').replaceAll('{count}', '$minutes');
  }
  
  String _notificationLabel(AppLocalizations t) {
    if (_notifyOffsetMinutes.isEmpty) return 'Keine';
    final labels = _notifyOffsetMinutes.map((m) => _offsetLabel(t, m)).toList();
    return labels.join(', ');
  }
  
  String _repeatLabel(AppLocalizations t) {
    // Nutze die verbesserte _repeatPreviewLabel Methode
    return _repeatPreviewLabel(t);
  }

  void _openReminderSheet() {
    final t = AppLocalizations.of(context);
    
    bool tempEnabled = _notificationEnabled;
    List<int> tempSelected = List.from(_notifyOffsetMinutes);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        bool showCustomPicker = false;
        int customAmount = 1;
        int customUnit = 1; // 0=Min, 1=Std, 2=Tag
        int? dynamicCustomValue;
        
        return StatefulBuilder(
          builder: (ctx, setSt) {
            // Custom-Werte dynamisch neu berechnen
            final customValues = tempSelected.where((m) => m != 0 && m != 10 && m != 60 && m != 1440).toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titel mit Zurück-Button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              // Auto-Save beim Schließen
                              setState(() {
                                _notificationEnabled = tempEnabled;
                                _notifyOffsetMinutes = tempSelected;
                              });
                              Navigator.pop(ctx);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.tr('maintenance.reminder_notification_title'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Ein/Aus Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2933),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.tr('maintenance.reminder_notification_enabled'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: tempEnabled,
                              onChanged: (v) => setSt(() => tempEnabled = v),
                              ),
                          ],
                        ),
                      ),
                      
                      if (tempEnabled) ...[
                        const SizedBox(height: 24),
                        
                        // Preset-Optionen mit Checkboxen
                        CheckboxListTile(
                          value: tempSelected.contains(0),
                          onChanged: (checked) {
                            setSt(() {
                              if (checked == true) {
                                tempSelected.add(0);
                              } else {
                                tempSelected.remove(0);
                              }
                            });
                          },
                          title: Text(t.maintenance_reminder_at_event, style: const TextStyle(color: Colors.white)),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: tempSelected.contains(10),
                          onChanged: (checked) {
                            setSt(() {
                              if (checked == true) {
                                tempSelected.add(10);
                              } else {
                                tempSelected.remove(10);
                              }
                            });
                          },
                          title: Text(t.maintenance_reminder_10m, style: const TextStyle(color: Colors.white)),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: tempSelected.contains(60),
                          onChanged: (checked) {
                            setSt(() {
                              if (checked == true) {
                                tempSelected.add(60);
                              } else {
                                tempSelected.remove(60);
                              }
                            });
                          },
                          title: Text(t.maintenance_reminder_1h, style: const TextStyle(color: Colors.white)),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: tempSelected.contains(1440),
                          onChanged: (checked) {
                            setSt(() {
                              if (checked == true) {
                                tempSelected.add(1440);
                              } else {
                                tempSelected.remove(1440);
                              }
                            });
                          },
                          title: Text(t.maintenance_reminder_1d, style: const TextStyle(color: Colors.white)),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        
                        // Zeige alle custom Werte als Checkboxen (persistent)
                        ...customValues.map((minutes) {
                          return CheckboxListTile(
                            value: tempSelected.contains(minutes),
                            onChanged: (checked) {
                              setSt(() {
                                if (checked == true) {
                                  tempSelected.add(minutes);
                                } else {
                                  tempSelected.remove(minutes);
                                }
                              });
                            },
                            title: Text(_offsetLabel(t, minutes), style: const TextStyle(color: Colors.white)),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                        
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Colors.white24),
                        const SizedBox(height: 16),
                        
                        // "Angepasst" Section
                        InkWell(
                          onTap: () => setSt(() => showCustomPicker = !showCustomPicker),
                          child: Row(
                            children: [
                              Icon(
                                showCustomPicker ? Icons.remove : Icons.add,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                t.maintenance_reminder_custom,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (showCustomPicker) ...[
                          const SizedBox(height: 16),
                          // Dynamische Custom-Option als Checkbox
                          Builder(
                            builder: (_) {
                              final mult = customUnit == 0 ? 1 : customUnit == 1 ? 60 : 1440;
                              final minutes = customAmount * mult;
                              final label = _offsetLabel(t, minutes);
                              
                              return CheckboxListTile(
                                value: tempSelected.contains(minutes),
                                onChanged: (checked) {
                                  setSt(() {
                                    if (checked == true) {
                                      tempSelected.add(minutes);
                                    } else {
                                      tempSelected.remove(minutes);
                                    }
                                  });
                                },
                                title: Text(label, style: const TextStyle(color: Colors.white)),
                                    contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2933),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Betrag
                                Expanded(
                                  child: CupertinoPicker(
                                    backgroundColor: Colors.transparent,
                                    itemExtent: 36,
                                    scrollController: FixedExtentScrollController(initialItem: customAmount - 1),
                                    onSelectedItemChanged: (i) {
                                      setSt(() {
                                        customAmount = i + 1;
                                        // Auto-update dynamicCustomValue
                                        final mult = customUnit == 0 ? 1 : customUnit == 1 ? 60 : 1440;
                                        dynamicCustomValue = customAmount * mult;
                                      });
                                    },
                                    children: List.generate(120, (i) {
                                      return Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(color: Colors.white, fontSize: 18),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // Einheit
                                Expanded(
                                  flex: 2,
                                  child: CupertinoPicker(
                                    backgroundColor: Colors.transparent,
                                    itemExtent: 36,
                                    scrollController: FixedExtentScrollController(initialItem: customUnit),
                                    onSelectedItemChanged: (i) {
                                      setSt(() {
                                        customUnit = i;
                                        // Auto-update dynamicCustomValue
                                        final mult = i == 0 ? 1 : i == 1 ? 60 : 1440;
                                        dynamicCustomValue = customAmount * mult;
                                      });
                                    },
                                    children: [
                                      Center(child: Text(t.tr('maintenance.reminder_custom_minute'), style: const TextStyle(color: Colors.white, fontSize: 18))),
                                      Center(child: Text(t.tr('maintenance.reminder_custom_hour'), style: const TextStyle(color: Colors.white, fontSize: 18))),
                                      Center(child: Text(t.tr('maintenance.reminder_custom_day'), style: const TextStyle(color: Colors.white, fontSize: 18))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      // Auto-Save beim Dismiss (außerhalb klicken)
      setState(() {
        _notificationEnabled = tempEnabled;
        _notifyOffsetMinutes = tempSelected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isEdit = widget.existing != null;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white54, width: 1),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24, width: 1),
          ),
        ),
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        title: Text(isEdit ? t.maintenance_edit_title : t.maintenance_create_title),
        backgroundColor: const Color(0xFF0F141A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
            // Kategorie (Icons statt Textchips)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_categories,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryGrid(t),
                  // Reifen: Sommer/Winter
                  if (_category == MaintenanceCategory.tireChange) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: _tireSummer,
                                onChanged: (v) => setState(() => _tireSummer = v ?? false),
                                  ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.maintenance_tires_summer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: _tireWinter,
                                onChanged: (v) => setState(() => _tireWinter = v ?? false),
                                  ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.maintenance_tires_winter,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Sonstiges: Custom-Category NUR wenn Inputfeld sichtbar ist
                  if (_showCustomCategoryInput) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customCategoryCtrl,
                            maxLength: 9,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: t.maintenance_custom_category_hint,
                              hintStyle: const TextStyle(color: Colors.white54),
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFF0F141A),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final label = _customCategoryCtrl.text.trim();
                            if (label.isEmpty) return;
                            await _addCustomCategory(label);
                          },
                          child: Text(t.maintenance_custom_category_save),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
            ),

            const SizedBox(height: 24),

            // Titel
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_title_label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                onTap: _checkLogin,
                decoration: InputDecoration(
                  hintText: t.maintenance_title_hint,
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFF151C23),
                ),
                style: const TextStyle(color: Colors.white),
                  validator: (v) => v == null || v.trim().isEmpty ? t.maintenance_title_required : null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Typ & Fälligkeit
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_reminders,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text(t.maintenance_type_date),
                            selected: _type == ReminderType.date,
                            onSelected: (_) => setState(() => _type = ReminderType.date),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(t.maintenance_type_mileage),
                            selected: _type == ReminderType.mileage,
                            onSelected: (_) => setState(() => _type = ReminderType.mileage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_type == ReminderType.date)
                      TextFormField(
                        controller: _dueDateTextCtrl,
                        readOnly: true,
                        onTap: _pickDueDate,
                        decoration: InputDecoration(
                          labelText: t.maintenance_due_date_label,
                          hintText: t.maintenance_due_date_hint,
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFF151C23),
                          suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (_) => _type == ReminderType.date && _dueDate == null ? t.maintenance_due_date_required : null,
                      )
                    else
                      TextFormField(
                        controller: _mileageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t.maintenance_due_mileage_label,
                          hintText: t.maintenance_due_mileage_hint,
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFF151C23),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (_) => _type == ReminderType.mileage && _mileageCtrl.text.trim().isEmpty ? t.maintenance_due_mileage_required : null,
                      ),
                ],
              ),
            ],
            ),

            const SizedBox(height: 24),

            // Glocke-Row + Wiederholen-Button (ohne Card, direkt auf Hintergrund)
            if (_type == ReminderType.date) ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openReminderSheet,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(_notificationEnabled ? Icons.notifications_active : Icons.notifications_off, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _notificationLabel(t),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openRepeatScreen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _repeatLabel(t),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Werkstatt (mit Autocomplete)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_workshop,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue tev) {
                      if (tev.text.isEmpty) return const Iterable<String>.empty();
                      final lower = tev.text.toLowerCase();
                      return _workshopBook.keys.where((k) => k.toLowerCase().contains(lower));
                    },
                    onSelected: (val) {
                      _workshopNameCtrl.text = val;
                      final addr = _workshopBook[val];
                      if (addr != null && addr.isNotEmpty) {
                        _workshopAddressCtrl.text = addr;
                      }
                      setState(() {});
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      controller.text = _workshopNameCtrl.text;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      controller.addListener(() { _workshopNameCtrl.text = controller.text; });
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: t.maintenance_workshop_name,
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: t.maintenance_workshop_name_hint,
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFF151C23),
                        ),
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _workshopAddressCtrl,
                    decoration: InputDecoration(
                      labelText: t.maintenance_workshop_address,
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: t.maintenance_workshop_address_hint,
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF151C23),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
            ),

            const SizedBox(height: 24),

            // Kosten & Kilometerstand
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_cost_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    TextFormField(
                      controller: _costCtrl,
                      decoration: InputDecoration(
                        labelText: t.maintenance_cost_title,
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: t.maintenance_cost_hint,
                        hintStyle: const TextStyle(color: Colors.white54),
                        suffixText: t.maintenance_cost_currency,
                        suffixStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFF151C23),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mileageAtMaintenanceCtrl,
                      decoration: InputDecoration(
                        labelText: t.maintenance_mileage_at_maintenance,
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: t.maintenance_mileage_hint,
                        hintStyle: const TextStyle(color: Colors.white54),
                        suffixText: t.maintenance_mileage_suffix,
                        suffixStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFF151C23),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(t.maintenance_add_to_vehicle_costs, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(t.maintenance_add_to_vehicle_costs_desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      value: _addToCosts,
                      onChanged: (val) => setState(() => _addToCosts = val),
                      activeColor: const Color(0xFFFFB129),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notizen
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_notes_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                decoration: InputDecoration(
                  hintText: t.maintenance_notes_hint,
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFF151C23),
                ),
                style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Fotos
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_photos_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Existierende Fotos aus der DB
                if (_photoKeys.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _photoKeys.map((key) => FutureBuilder<String?>(
                          future: MaintenanceService(Supabase.instance.client).getSignedUrl(key),
                          builder: (context, snapshot) {
                            final url = snapshot.data;
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: url == null ? null : () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogCtx) => Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.pop(dialogCtx),
                                            child: Container(
                                              color: Colors.black,
                                              child: InteractiveViewer(
                                                child: Image.network(url!),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 20,
                                            right: 20,
                                            child: GestureDetector(
                                              onTap: () => Navigator.pop(dialogCtx),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, color: Colors.white, size: 24),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: url == null
                                        ? Container(
                                            width: 80,
                                            height: 80,
                                            color: const Color(0xFF0F141A),
                                            child: const Center(child: CircularProgressIndicator()),
                                          )
                                        : Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _photoKeys.remove(key)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        )).toList(),
                      ),
                    ),
                if (_photoKeys.isNotEmpty && _localPhotos.isNotEmpty) const SizedBox(height: 8),
                // Lokale Fotos (noch nicht hochgeladen)
                if (_localPhotos.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _localPhotos.map((f) => Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () => Navigator.pop(dialogCtx),
                                        child: Container(
                                          color: Colors.black,
                                          child: InteractiveViewer(
                                            child: Image.file(f),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 20,
                                        right: 20,
                                        child: GestureDetector(
                                          onTap: () => Navigator.pop(dialogCtx),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 24),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _localPhotos.remove(f)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )).toList(),
                      ),
                    ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB129),
                      side: const BorderSide(color: Color(0xFFFFB129), width: 1),
                    ),
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(t.maintenance_photos_add),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dokumente
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_documents_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                children: [
                  // Existierende Dokumente aus der DB
                  if (_documentKeys.isNotEmpty)
                    Column(
                      children: _documentKeys.map((key) => FutureBuilder<String?>(
                        future: MaintenanceService(Supabase.instance.client).getSignedUrl(key),
                        builder: (context, snapshot) {
                          final url = snapshot.data;
                          return ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(t.tr('maintenance.pdf_document'), style: const TextStyle(color: Colors.white)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => setState(() => _documentKeys.remove(key)),
                            ),
                            onTap: url == null ? null : () async {
                              final uri = Uri.parse(url);
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            tileColor: const Color(0xFF0F141A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        },
                      )).toList(),
                    ),
                  if (_documentKeys.isNotEmpty && _localDocuments.isNotEmpty) const SizedBox(height: 8),
                  // Lokale Dokumente (noch nicht hochgeladen)
                  if (_localDocuments.isNotEmpty)
                    Column(
                      children: _localDocuments.map((f) => ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(f.path.split('/').last, style: const TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => setState(() => _localDocuments.remove(f)),
                        ),
                        tileColor: const Color(0xFF0F141A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      )).toList(),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB129),
                      side: const BorderSide(color: Color(0xFFFFB129), width: 1),
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: Text(t.maintenance_documents_upload_pdf),
                  ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Speichern-Button (unten)
            SizedBox(
              width: double.infinity,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB129),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(t.maintenance_save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
            ),

            const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryGrid(AppLocalizations t) {
    // Versicherung und KFZ-Steuer ausblenden
    final categories = MaintenanceCategory.values
        .where((cat) => cat != MaintenanceCategory.insurance && cat != MaintenanceCategory.tax)
        .toList();
    
    // Custom-Categories VOR "Sonstiges" einfügen
    final allTiles = <Widget>[];
    
    for (var cat in categories) {
      // Wenn wir bei "other" sind, füge Custom-Categories DAVOR ein
      if (cat == MaintenanceCategory.other) {
        allTiles.addAll(_customCategories.map((label) {
          final isSelected = _customSelectedLabel == label;
          final icon = _customCategoryIcons[label] ?? Icons.help_outline;
          return _CategoryIconTile(
            icon: icon,
            label: label,
            color: const Color(0xFF90A4AE),
            selected: isSelected,
            isLocked: false, // Custom-Categories sind immer frei
            onTap: () => setState(() {
              _customSelectedLabel = label;
              _category = MaintenanceCategory.other;
            }),
            onLongPress: () => _showDeleteCustomCategoryDialog(label),
          );
        }));
      }
      
      // Normale Kategorie hinzufügen
      final isSelected = _category == cat && (cat != MaintenanceCategory.other || _customSelectedLabel == null);
      final isLocked = !cat.isFreeCategory; // Nicht in freien 4 Kategorien
      final icon = _getCategoryIcon(cat);
      final color = _getCategoryColor(cat);
      allTiles.add(_CategoryIconTile(
        icon: icon,
        label: _getCategoryLabel(t, cat),
        color: color,
        selected: isSelected,
        isLocked: isLocked,
        onTap: () {
          _checkLoginAndSetCategory(cat);
        },
      ));
    }
    
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: allTiles,
    );
  }

  IconData _getCategoryIcon(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return Icons.oil_barrel_outlined;
      case MaintenanceCategory.tireChange:
        return Icons.tire_repair;
      case MaintenanceCategory.brakes:
        return Icons.handyman_outlined;
      case MaintenanceCategory.tuv:
        return Icons.verified_outlined;
      case MaintenanceCategory.inspection:
        return Icons.build_circle_outlined;
      case MaintenanceCategory.battery:
        return Icons.battery_charging_full;
      case MaintenanceCategory.filter:
        return Icons.filter_alt_outlined;
      case MaintenanceCategory.insurance:
        return Icons.shield_outlined;
      case MaintenanceCategory.tax:
        return Icons.receipt_long_outlined;
      case MaintenanceCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return const Color(0xFFFFB74D);
      case MaintenanceCategory.tireChange:
        return const Color(0xFF64B5F6);
      case MaintenanceCategory.brakes:
        return const Color(0xFFE57373);
      case MaintenanceCategory.tuv:
        return const Color(0xFF81C784);
      case MaintenanceCategory.inspection:
        return const Color(0xFF9575CD);
      case MaintenanceCategory.battery:
        return const Color(0xFFFFD54F);
      case MaintenanceCategory.filter:
        return const Color(0xFF4DD0E1);
      case MaintenanceCategory.insurance:
        return const Color(0xFF26A69A);
      case MaintenanceCategory.tax:
        return const Color(0xFF90CAF9);
      case MaintenanceCategory.other:
        return const Color(0xFF90A4AE);
    }
  }

  String _getCategoryLabel(AppLocalizations t, MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return t.maintenance_category_oil_change;
      case MaintenanceCategory.tireChange:
        return t.maintenance_category_tire_change;
      case MaintenanceCategory.brakes:
        return t.maintenance_category_brakes;
      case MaintenanceCategory.tuv:
        return t.maintenance_category_tuv;
      case MaintenanceCategory.inspection:
        return t.maintenance_category_inspection;
      case MaintenanceCategory.battery:
        return t.maintenance_category_battery;
      case MaintenanceCategory.filter:
        return t.maintenance_category_filter;
      case MaintenanceCategory.insurance:
        return t.maintenance_category_insurance;
      case MaintenanceCategory.tax:
        return t.maintenance_category_tax;
      case MaintenanceCategory.other:
        return t.maintenance_category_other;
    }
  }

  String _getCategoryIconName(MaintenanceCategory cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange: return 'oil_barrel_outlined';
      case MaintenanceCategory.tireChange: return 'tire_repair';
      case MaintenanceCategory.brakes: return 'handyman_outlined';
      case MaintenanceCategory.tuv: return 'verified_outlined';
      case MaintenanceCategory.inspection: return 'build_circle_outlined';
      case MaintenanceCategory.battery: return 'battery_charging_full';
      case MaintenanceCategory.filter: return 'filter_alt_outlined';
      case MaintenanceCategory.insurance: return 'shield_outlined';
      case MaintenanceCategory.tax: return 'receipt_long_outlined';
      case MaintenanceCategory.other: return 'more_horiz';
    }
  }

  void _checkLogin() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // User not logged in - redirect to login
      context.go('/auth');
    }
  }

  Future<void> _checkLoginAndSetCategory(MaintenanceCategory cat) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _checkLogin();
      return;
    }
    
    // Paywall-Check: Nur 4 Kategorien für Free-User
    final isPro = await PurchaseService().isPro();
    if (!isPro && !cat.isFreeCategory) {
      _showCategoryLockedDialog();
      return;
    }
    
    setState(() {
      _category = cat;
      if (cat == MaintenanceCategory.other) {
        // Toggle Inputfeld für Sonstiges
        _showCustomCategoryInput = !_showCustomCategoryInput;
        if (!_showCustomCategoryInput) {
          _customCategoryCtrl.clear();
        }
      } else {
        _customSelectedLabel = null;
        _showCustomCategoryInput = false;
      }
    });
  }

  void _showCategoryLockedDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, color: Color(0xFFFFB129)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.tr('dialog.category_locked_title'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('maintenance.lock_message'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('dialog.unlock_with'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFB129), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.tr('subscription.pro_monthly'),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Text(
                      '4,99 € / ${t.tr('repeat.month')}',
                      style: TextStyle(
                        color: Color(0xFFFFB129),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.tr('common.cancel'), style: const TextStyle(color: Colors.white60)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/paywall');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB129),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(t.tr('common.go_to_paywall')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _workshopNameCtrl.dispose();
    _workshopAddressCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    _mileageCtrl.dispose();
    _mileageAtMaintenanceCtrl.dispose();
    _dateFocusNode.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }
}

Widget _buildRepeatOption<T>({
  required T value,
  required T? groupValue,
  required String label,
  required VoidCallback onTap,
  Widget? customChild,
}) {
  final isSelected = value == groupValue;
  
  // Wenn customChild vorhanden ist, zeige es statt des Standard-Layouts
  if (customChild != null) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: customChild,
      ),
    );
  }
  
  // Standard-Layout: Einfacher Radio-Button ohne Hintergrund
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? Colors.blue : Colors.white54,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSecondaryButton(String label, {required bool isSelected, required VoidCallback onTap}) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.white30,
        width: isSelected ? 2 : 1,
      ),
      backgroundColor: isSelected ? Colors.blue.withOpacity(0.1) : const Color(0xFF1F2933),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

class _CategoryIconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CategoryIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    this.isLocked = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: (isLocked ? color.withOpacity(0.05) : color.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
                ),
                child: Icon(
                  icon, 
                  color: isLocked ? color.withOpacity(0.3) : color, 
                  size: 24
                ),
              ),
              if (isLocked)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB129),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w600, 
              color: isLocked ? Colors.white38 : Colors.white
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22303D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
