import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/login_required_dialog.dart';

class AddReminderDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const AddReminderDialog({super.key, required this.onSaved});

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
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
      Navigator.of(context).pop();
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
        recurrenceIntervalKm: _isRecurring && _type == ReminderType.mileage
            ? int.tryParse(_mileageCtrl.text)
            : null,
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_note,
                          color: Color(0xFF1976D2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Neue Erinnerung',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Titel
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Titel *',
                      hintText: 'z.B. Ölwechsel, Inspektion',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Bitte einen Titel eingeben' : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Beschreibung
                  TextFormField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Beschreibung (optional)',
                      hintText: 'Weitere Details...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),

                  // Typ-Auswahl
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TypeButton(
                            icon: Icons.event,
                            label: 'Datum',
                            isSelected: _type == ReminderType.date,
                            onTap: () => setState(() => _type = ReminderType.date),
                          ),
                        ),
                        Expanded(
                          child: _TypeButton(
                            icon: Icons.speed,
                            label: 'Kilometer',
                            isSelected: _type == ReminderType.mileage,
                            onTap: () => setState(() => _type = ReminderType.mileage),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Datum/Kilometer Input
                  if (_type == ReminderType.date)
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0A0A0A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    TextFormField(
                      controller: _mileageCtrl,
                      decoration: InputDecoration(
                        labelText: 'Kilometerstand *',
                        hintText: 'z.B. 150000',
                        suffixText: 'km',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (_type == ReminderType.mileage) {
                          if (v?.trim().isEmpty == true) return 'Bitte Kilometer eingeben';
                          if (int.tryParse(v!) == null) return 'Ungültige Zahl';
                        }
                        return null;
                      },
                    ),

                  const SizedBox(height: 20),

                  // Wiederkehrend
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Wiederkehrend',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _type == ReminderType.date
                                    ? 'Alle $_recurringMonths Monate'
                                    : 'Alle ${_mileageCtrl.text.isEmpty ? "..." : _mileageCtrl.text} km',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isRecurring,
                          onChanged: (v) => setState(() => _isRecurring = v),
                          activeColor: const Color(0xFF1976D2),
                        ),
                      ],
                    ),
                  ),

                  if (_isRecurring && _type == ReminderType.date) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Wiederholung alle:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [3, 6, 12].map((months) {
                        final isSelected = _recurringMonths == months;
                        return ChoiceChip(
                          label: Text('$months Monate'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _recurringMonths = months);
                          },
                          selectedColor: const Color(0xFF1976D2),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
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
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Speichern',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
