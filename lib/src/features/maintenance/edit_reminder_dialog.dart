import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/login_required_dialog.dart';

class EditReminderDialog extends StatefulWidget {
  final MaintenanceReminder reminder;
  final VoidCallback onSaved;

  const EditReminderDialog({
    super.key,
    required this.reminder,
    required this.onSaved,
  });

  @override
  State<EditReminderDialog> createState() => _EditReminderDialogState();
}

class _EditReminderDialogState extends State<EditReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = MaintenanceService(Supabase.instance.client);
  
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _mileageCtrl;
  
  late ReminderType _type;
  late DateTime _selectedDate;
  late bool _isRecurring;
  late int _recurringMonths;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.reminder.title);
    _descCtrl = TextEditingController(text: widget.reminder.description ?? '');
    _mileageCtrl = TextEditingController(
      text: widget.reminder.dueMileage?.toString() ?? '',
    );
    
    _type = widget.reminder.reminderType;
    _selectedDate = widget.reminder.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _isRecurring = widget.reminder.isRecurring;
    
    // Berechne Monate aus Tagen
    if (widget.reminder.recurrenceIntervalDays != null) {
      _recurringMonths = (widget.reminder.recurrenceIntervalDays! / 30).round();
    } else {
      _recurringMonths = 6;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Login-Check
    if (Supabase.instance.client.auth.currentUser == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showLoginRequiredDialog(context);
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.updateReminder(
        id: widget.reminder.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        dueDate: _type == ReminderType.date ? _selectedDate : null,
        dueMileage: _type == ReminderType.mileage ? int.tryParse(_mileageCtrl.text) : null,
        isRecurring: _isRecurring,
        recurrenceIntervalDays: _isRecurring && _type == ReminderType.date 
            ? _recurringMonths * 30 
            : null,
        recurrenceIntervalKm: null, // TODO: Implement if needed
      );
      
      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  t.maintenance_edit_title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),

                // Titel
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: t.maintenance_title_label,
                    hintText: t.maintenance_title_hint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v?.isEmpty ?? true ? t.maintenance_title_required : null,
                ),
                const SizedBox(height: 16),

                // Typ-Auswahl
                Text(t.maintenance_reminder_type, style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(t.maintenance_type_date),
                        selected: _type == ReminderType.date,
                        onSelected: (sel) => setState(() => _type = ReminderType.date),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(t.maintenance_type_mileage),
                        selected: _type == ReminderType.mileage,
                        onSelected: (sel) => setState(() => _type = ReminderType.mileage),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Datum ODER Kilometer
                if (_type == ReminderType.date) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.maintenance_due_date_label),
                    subtitle: Text('${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _mileageCtrl,
                    decoration: InputDecoration(
                      labelText: t.maintenance_mileage_label,
                      hintText: t.maintenance_mileage_hint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixText: t.maintenance_mileage_suffix,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v?.isEmpty ?? true ? t.maintenance_mileage_required : null,
                  ),
                ],
                const SizedBox(height: 16),

                // Wiederkehrend
                if (_type == ReminderType.date) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.maintenance_recurring),
                    subtitle: Text(t.maintenance_recurring_subtitle),
                    value: _isRecurring,
                    onChanged: (val) => setState(() => _isRecurring = val),
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    Text(t.maintenance_interval, style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(t.maintenance_interval_3_months),
                          selected: _recurringMonths == 3,
                          onSelected: (sel) => setState(() => _recurringMonths = 3),
                        ),
                        ChoiceChip(
                          label: Text(t.maintenance_interval_6_months),
                          selected: _recurringMonths == 6,
                          onSelected: (sel) => setState(() => _recurringMonths = 6),
                        ),
                        ChoiceChip(
                          label: Text(t.maintenance_interval_12_months),
                          selected: _recurringMonths == 12,
                          onSelected: (sel) => setState(() => _recurringMonths = 12),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 16),

                // Beschreibung
                TextFormField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    labelText: t.maintenance_description_label,
                    hintText: t.maintenance_description_hint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(t.maintenance_cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                t.maintenance_save,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
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
}
