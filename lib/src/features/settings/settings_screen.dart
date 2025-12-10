import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';
import '../../state/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider);
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header mit Back Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C23),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            GoRouter.of(context).go('/profile');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.settings_title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Allgemein Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.settings_general,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _LanguageTile(),
                    const SizedBox(height: 16),
                    const _NotificationsTile(),
                    
                    // Konto-Section nur für eingeloggte User
                    if (isLoggedIn) ...[
                      const SizedBox(height: 28),
                      Text(
                        t.settings_account,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _AccountPlaceholders(),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsTile extends StatefulWidget {
  const _NotificationsTile();
  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('notifications_enabled_global') ?? true;
      _loading = false;
    });
  }

  Future<void> _set(bool value) async {
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled_global', value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFFF9800), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.settings_notifications,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _enabled ? t.tr('settings.notifications_disable') : t.tr('settings.notifications_enable'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Switch(value: _enabled, onChanged: _set),
        ],
      ),
    );
  }
}


class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language, color: Color(0xFF2196F3), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: ref.watch(appLocaleProvider),
                hint: const Text('Sprache', style: TextStyle(color: Colors.white54)),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                dropdownColor: const Color(0xFF151C23),
                iconEnabledColor: Colors.white54,
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
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        _SettingsTile(icon: Icons.email_outlined, label: t.settings_change_email, onTap: () => _changeEmail(context)),
        const SizedBox(height: 8),
        _SettingsTile(icon: Icons.lock_outline, label: t.settings_change_password, onTap: () => _changePassword(context)),
        const SizedBox(height: 8),
        _SettingsTile(icon: Icons.logout, label: t.settings_logout, onTap: () => _logout(context)),
      ],
    );
  }

  Future<void> _changeEmail(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final supa = Supabase.instance.client;
    final current = supa.auth.currentUser?.email ?? '';
    final controller = TextEditingController(text: current);
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151C23),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(t.settings_change_email_title, style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 600,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Neue E-Mail',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(t.tr('common.cancel'), style: const TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.tr('common.save')),
            ),
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
    final t = AppLocalizations.of(context);
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
            backgroundColor: const Color(0xFF151C23),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(t.settings_change_password_title, style: const TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 600,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pass1,
                  obscureText: !show1,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Neues Passwort',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    suffixIcon: IconButton(
                      icon: Icon(show1 ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                      onPressed: () => setState(() => show1 = !show1),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pass2,
                  obscureText: !show2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Passwort bestätigen',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    suffixIcon: IconButton(
                      icon: Icon(show2 ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(t.tr('common.cancel'), style: const TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(t.tr('common.save')),
              ),
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
    // Bestimme Farben basierend auf Icon-Typ
    Color iconColor;
    Color iconBg;
    if (icon == Icons.logout) {
      iconColor = const Color(0xFFE53935);
      iconBg = const Color(0xFFE53935).withOpacity(0.2);
    } else if (icon == Icons.email_outlined) {
      iconColor = const Color(0xFF9C27B0); // Lila
      iconBg = const Color(0xFF9C27B0).withOpacity(0.2);
    } else if (icon == Icons.lock_outline) {
      iconColor = const Color(0xFF4CAF50); // Grün
      iconBg = const Color(0xFF4CAF50).withOpacity(0.2);
    } else {
      // Fallback (z.B. Benachrichtigungen wenn hier genutzt, oder andere)
      iconColor = const Color(0xFFFFB129);
      iconBg = const Color(0xFFFFB129).withOpacity(0.2);
    }

    return Material(
      color: const Color(0xFF151C23),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
