import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/login_required_dialog.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MaintenanceService(Supabase.instance.client);
  
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  
  ReminderType _type = ReminderType.date;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isRecurring = false;
  int _recurringMonths = 6;
  bool _saving = false;

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
      showLoginRequiredDialog(context);
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.createReminder(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        reminderType: _type,
        dueDate: _type == ReminderType.date ? _selectedDate : null,
        dueMileage: _type == ReminderType.mileage ? int.tryParse(_mileageCtrl.text) : null,
        isRecurring: _isRecurring,
        recurrenceIntervalDays: _isRecurring && _type == ReminderType.date
            ? _recurringMonths * 30
            : null,
        recurrenceIntervalKm: null,
      );

      if (!mounted) return;
      // Zurück zum Dashboard - pop() statt go() damit await ausgelöst wird
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A0A0A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.maintenance_create_title,
          style: TextStyle(
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Titel
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: t.maintenance_title_label,
                hintText: t.maintenance_title_hint,
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (v) => v?.isEmpty ?? true ? t.maintenance_title_required : null,
            ),
            const SizedBox(height: 20),

            // Typ-Auswahl
            Text(
              t.maintenance_reminder_type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 18),
                        SizedBox(width: 8),
                        Text(t.maintenance_type_date),
                      ],
                    ),
                    selected: _type == ReminderType.date,
                    onSelected: (sel) {
                      if (sel) setState(() => _type = ReminderType.date);
                    },
                    selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.speed, size: 18),
                        SizedBox(width: 8),
                        Text(t.maintenance_type_mileage),
                      ],
                    ),
                    selected: _type == ReminderType.mileage,
                    onSelected: (sel) {
                      if (sel) setState(() => _type = ReminderType.mileage);
                    },
                    selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Datum ODER Kilometer
            if (_type == ReminderType.date) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                  title: Text(t.maintenance_due_date_label),
                  subtitle: Text(
                    '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickDate,
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _mileageCtrl,
                decoration: InputDecoration(
                  labelText: t.maintenance_mileage_label,
                  hintText: t.maintenance_mileage_hint,
                  prefixIcon: const Icon(Icons.speed),
                  suffixText: t.maintenance_mileage_suffix,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v?.isEmpty ?? true ? t.maintenance_mileage_required : null,
              ),
            ],
            const SizedBox(height: 24),

            // Wiederkehrend
            if (_type == ReminderType.date) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SwitchListTile(
                  title: Text(
                    t.maintenance_recurring,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(t.maintenance_recurring_subtitle),
                  value: _isRecurring,
                  onChanged: (val) => setState(() => _isRecurring = val),
                  activeColor: const Color(0xFF1976D2),
                ),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                Text(
                  t.maintenance_interval,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    ChoiceChip(
                      label: Text(t.maintenance_interval_3_months),
                      selected: _recurringMonths == 3,
                      onSelected: (sel) {
                        if (sel) setState(() => _recurringMonths = 3);
                      },
                      selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                    ),
                    ChoiceChip(
                      label: Text(t.maintenance_interval_6_months),
                      selected: _recurringMonths == 6,
                      onSelected: (sel) {
                        if (sel) setState(() => _recurringMonths = 6);
                      },
                      selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                    ),
                    ChoiceChip(
                      label: Text(t.maintenance_interval_12_months),
                      selected: _recurringMonths == 12,
                      onSelected: (sel) {
                        if (sel) setState(() => _recurringMonths = 12);
                      },
                      selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Beschreibung
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: t.maintenance_description_label,
                hintText: t.maintenance_description_hint,
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: Text(
                      t.maintenance_cancel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
