import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../i18n/app_localizations.dart';

/// Zeigt einen Dialog an wenn Login erforderlich ist
void showLoginRequiredDialog(BuildContext context, {String? message}) {
  final t = AppLocalizations.of(context);
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        t.tr('login_dialog.title'),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      content: Text(
        message ?? t.tr('login_dialog.default_message'),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            t.tr('diagnose.cancel'),
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            context.go('/auth');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0384F4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            t.tr('diagnose.login_now'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}
