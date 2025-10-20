import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _loadExisting();
    }
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
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          photos: _photoKeys.isEmpty ? null : _photoKeys,
          documents: _documentKeys.isEmpty ? null : _documentKeys,
          isRecurring: _isRecurring,
          recurrenceIntervalDays: _isRecurring && _intervalMonths != null ? _intervalMonths! * 30 : null,
          notificationEnabled: _notificationEnabled,
        );
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEdit ? t.maintenance_edit_title : t.maintenance_create_title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ))
          else
            TextButton(
              onPressed: _save,
              child: Text(t.maintenance_save, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Kategorie
            _SectionCard(
              title: t.maintenance_categories,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MaintenanceCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return FilterChip(
                    label: Text(_getCategoryLabel(t, cat)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF1976D2),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Titel
            _SectionCard(
              title: t.maintenance_title_label,
              child: TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: t.maintenance_title_hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? t.maintenance_title_required : null,
              ),
            ),

            const SizedBox(height: 16),

            // Typ & Fälligkeit
            _SectionCard(
              title: t.maintenance_reminder_type,
              child: Column(
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
                    ListTile(
                      title: Text(_dueDate == null ? t.maintenance_due_date_label : '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    )
                  else
                    TextFormField(
                      controller: _mileageCtrl,
                      decoration: InputDecoration(
                        labelText: t.maintenance_mileage_label,
                        hintText: t.maintenance_mileage_hint,
                        suffixText: t.maintenance_mileage_suffix,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Werkstatt
            _SectionCard(
              title: t.maintenance_workshop,
              child: Column(
                children: [
                  TextFormField(
                    controller: _workshopNameCtrl,
                    decoration: InputDecoration(
                      labelText: t.maintenance_workshop_name,
                      hintText: t.maintenance_workshop_name_hint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _workshopAddressCtrl,
                    decoration: InputDecoration(
                      labelText: t.maintenance_workshop_address,
                      hintText: t.maintenance_workshop_address_hint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kosten & Kilometerstand
            _SectionCard(
              title: t.maintenance_cost_title,
              child: Column(
                children: [
                  TextFormField(
                    controller: _costCtrl,
                    decoration: InputDecoration(
                      labelText: t.maintenance_cost_title,
                      hintText: t.maintenance_cost_hint,
                      suffixText: t.maintenance_cost_currency,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mileageAtMaintenanceCtrl,
                    decoration: InputDecoration(
                      labelText: t.maintenance_mileage_at_maintenance,
                      hintText: t.maintenance_mileage_hint,
                      suffixText: t.maintenance_mileage_suffix,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notizen
            _SectionCard(
              title: t.maintenance_notes_title,
              child: TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  hintText: t.maintenance_notes_hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
              ),
            ),

            const SizedBox(height: 16),

            // Fotos
            _SectionCard(
              title: t.maintenance_photos_title,
              child: Column(
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
            ),

            const SizedBox(height: 16),

            // Dokumente
            _SectionCard(
              title: t.maintenance_documents_title,
              child: Column(
                children: [
                  if (_localDocuments.isNotEmpty)
                    Column(
                      children: _localDocuments.map((f) => ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(f.path.split('/').last),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _localDocuments.remove(f)),
                        ),
                        tileColor: Colors.white,
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
            ),

            const SizedBox(height: 16),

            // Wiederkehrend & Benachrichtigungen
            _SectionCard(
              title: t.maintenance_recurring,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(t.maintenance_recurring),
                    subtitle: Text(t.maintenance_recurring_subtitle),
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
                    title: Text(t.maintenance_notification_enabled),
                    subtitle: Text(t.maintenance_notification_subtitle),
                    value: _notificationEnabled,
                    onChanged: (v) => setState(() => _notificationEnabled = v),
                    activeColor: const Color(0xFF1976D2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
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
    super.dispose();
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
