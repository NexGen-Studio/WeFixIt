import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';

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

  MaintenanceCategory? _category;
  ReminderType _type = ReminderType.date;
  DateTime? _dueDate;
  bool _isRecurring = false;
  int? _intervalMonths;
  bool _notificationEnabled = true;
  bool _loading = false;

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
    if (e.dueMileage != null) _mileageCtrl.text = e.dueMileage.toString();
    if (e.mileageAtMaintenance != null) {
      _mileageAtMaintenanceCtrl.text = e.mileageAtMaintenance.toString();
    }
    _workshopNameCtrl.text = e.workshopName ?? '';
    _workshopAddressCtrl.text = e.workshopAddress ?? '';
    if (e.cost != null) _costCtrl.text = e.cost.toString();
    _notesCtrl.text = e.notes ?? '';
    _isRecurring = e.isRecurring;
    _notificationEnabled = e.notificationEnabled;
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

      if (widget.existing == null) {
        // Neu erstellen
        await svc.createReminder(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: _category,
          reminderType: _type,
          dueDate: _type == ReminderType.date ? _dueDate : null,
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
          isRecurring: _isRecurring,
          recurrenceIntervalDays: _isRecurring && _intervalMonths != null ? _intervalMonths! * 30 : null,
          notificationEnabled: _notificationEnabled,
        );
      } else {
        // Aktualisieren
        await svc.updateReminder(
          id: widget.existing!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: _category,
          dueDate: _type == ReminderType.date ? _dueDate : null,
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
          isRecurring: _isRecurring,
          recurrenceIntervalDays: _isRecurring && _intervalMonths != null ? _intervalMonths! * 30 : null,
          notificationEnabled: _notificationEnabled,
        );
      }

      // Werkstatt merken
      await _rememberWorkshop(_workshopNameCtrl.text.trim(), _workshopAddressCtrl.text.trim());

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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        title: Text(isEdit ? t.maintenance_edit_title : t.maintenance_create_title),
        backgroundColor: const Color(0xFF0F141A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
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
                          child: CheckboxListTile(
                            value: _tireSummer,
                            onChanged: (v) => setState(() => _tireSummer = v ?? false),
                            title: Text(t.maintenance_tires_summer, style: const TextStyle(color: Colors.white)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CheckboxListTile(
                            value: _tireWinter,
                            onChanged: (v) => setState(() => _tireWinter = v ?? false),
                            title: Text(t.maintenance_tires_winter, style: const TextStyle(color: Colors.white)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF1976D2),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                          ),
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
                  t.maintenance_reminder_type,
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
                    Focus(
                      focusNode: _dateFocusNode,
                      child: ListTile(
                        title: Text(
                          _dueDate == null ? t.maintenance_due_date_label : '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                        onTap: () async {
                          _dateFocusNode.requestFocus();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                            _dateFocusNode.unfocus();
                          }
                        },
                        tileColor: const Color(0xFF151C23),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    TextFormField(
                      controller: _mileageCtrl,
                      decoration: InputDecoration(
                        labelText: t.maintenance_mileage_label,
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
                ],
              ),
            ],
            ),

            const SizedBox(height: 24),

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
                Column(
                  children: [
                  if (_localPhotos.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _localPhotos.map((f) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(t.maintenance_photos_add),
                  ),
                  ],
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
                    icon: const Icon(Icons.upload_file),
                    label: Text(t.maintenance_documents_upload_pdf),
                  ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Wiederkehrend & Benachrichtigungen
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.maintenance_recurring,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                children: [
                  SwitchListTile(
                    title: Text(t.maintenance_recurring, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.maintenance_recurring_subtitle, style: const TextStyle(color: Colors.white70)),
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                    activeColor: const Color(0xFF1976D2),
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [3, 6, 12].map((months) {
                        final isSelected = _intervalMonths == months;
                        return ChoiceChip(
                          label: Text('$months ${t.maintenance_interval_12_months.split(' ')[1]}'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _intervalMonths = months),
                        );
                      }).toList(),
                    ),
                  ],
                  const Divider(),
                  SwitchListTile(
                    title: Text(t.maintenance_notification_enabled, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.maintenance_notification_subtitle, style: const TextStyle(color: Colors.white70)),
                    value: _notificationEnabled,
                    onChanged: (v) => setState(() => _notificationEnabled = v),
                    activeColor: const Color(0xFF1976D2),
                  ),
                  const SizedBox(height: 24),
                  // Speichern-Button
                  SizedBox(
                    width: double.infinity,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(t.maintenance_save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                  ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 100),
          ],
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
      final icon = _getCategoryIcon(cat);
      final color = _getCategoryColor(cat);
      allTiles.add(_CategoryIconTile(
        icon: icon,
        label: _getCategoryLabel(t, cat),
        color: color,
        selected: isSelected,
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

  void _checkLogin() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bitte melde dich an, um Wartungen zu erstellen'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Anmelden',
            textColor: Colors.white,
            onPressed: () => context.go('/login'),
          ),
        ),
      );
    }
  }

  void _checkLoginAndSetCategory(MaintenanceCategory cat) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _checkLogin();
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

class _CategoryIconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CategoryIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
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
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
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
