import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        foregroundColor: const Color(0xFF636564),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go('/profile');
            }
          },
        ),
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
                color: const Color(0xFF636564),
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
        _SettingsTile(icon: Icons.email_outlined, label: 'E-Mail ändern', onTap: () => _changeEmail(context)),
        const SizedBox(height: 8),
        _SettingsTile(icon: Icons.lock_outline, label: 'Passwort ändern', onTap: () => _changePassword(context)),
        const SizedBox(height: 8),
        _SettingsTile(icon: Icons.logout, label: 'Logout', onTap: () => _logout(context)),
      ],
    );
  }

  Future<void> _changeEmail(BuildContext context) async {
    final supa = Supabase.instance.client;
    final current = supa.auth.currentUser?.email ?? '';
    final controller = TextEditingController(text: current);
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('E-Mail ändern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Neue E-Mail'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Abbrechen')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Speichern')),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final email = controller.text.trim();
    if (email.isEmpty || email == current) return;
    try {
      await supa.auth.updateUser(UserAttributes(email: email));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bestätigungs-E-Mail gesendet.')));
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etwas ist schiefgelaufen.')));
      }
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final pass1 = TextEditingController();
    final pass2 = TextEditingController();
    bool show1 = false;
    bool show2 = false;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Passwort ändern'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pass1,
                  obscureText: !show1,
                  decoration: InputDecoration(
                    labelText: 'Neues Passwort',
                    suffixIcon: IconButton(
                      icon: Icon(show1 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => show1 = !show1),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pass2,
                  obscureText: !show2,
                  decoration: InputDecoration(
                    labelText: 'Passwort bestätigen',
                    suffixIcon: IconButton(
                      icon: Icon(show2 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => show2 = !show2),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Abbrechen')),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Speichern')),
            ],
          );
        });
      },
    );
    if (ok != true) return;
    if (pass1.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mindestens 6 Zeichen.')));
      return;
    }
    if (pass1.text != pass2.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwörter stimmen nicht überein.')));
      return;
    }
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: pass1.text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwort aktualisiert.')));
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etwas ist schiefgelaufen.')));
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (context.mounted) {
      GoRouter.of(context).go('/home');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abgemeldet.')));
    }
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
