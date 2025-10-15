import 'package:flutter/material.dart';
import '../../i18n/app_localizations.dart';

class DiagnoseScreen extends StatelessWidget {
  const DiagnoseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF636564),
        title: Text(t.tr('diagnose.title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.tr('diagnose.subtitle'),
              style: const TextStyle(color: Color(0xFF636564), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _LightButton(label: t.tr('diagnose.read_dtc'), onPressed: () {}),
            const SizedBox(height: 12),
            _LightButton(label: t.tr('diagnose.clear_dtc'), onPressed: () {}),
            const SizedBox(height: 12),
            _LightButton(label: t.tr('diagnose.ai_diagnose'), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _LightButton extends StatelessWidget {
  const _LightButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
