import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('Allgemein'),
          _LanguageTile(),
          SizedBox(height: 16),
          _SectionTitle('Konto'),
          _AccountPlaceholders(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.language, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: ref.watch(appLocaleProvider),
                hint: const Text('Sprache', style: TextStyle(color: Colors.black54)),
                style: const TextStyle(color: Colors.black),
                dropdownColor: const Color(0xFFE0E0E0),
                iconEnabledColor: Colors.black54,
                items: const [
                  DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                ],
                onChanged: (loc) => setAppLocale(ref, loc),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountPlaceholders extends StatelessWidget {
  const _AccountPlaceholders();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(icon: Icons.email_outlined, label: 'E-Mail ändern', onTap: () {}),
        const SizedBox(height: 8),
        _SettingsTile(icon: Icons.lock_outline, label: 'Passwort ändern', onTap: () {}),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
