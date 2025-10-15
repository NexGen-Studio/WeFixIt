import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final t = AppLocalizations.of(context);
    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.tr('auth.reset_email_sent'))),
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (!mounted) return;
        // Direkt nach erfolgreichem Login weiterleiten
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // ignore: use_build_context_synchronously
          GoRouter.of(context).go('/home');
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = t.tr('auth.error_generic'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.tr('auth.title')),
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.tr(_isSignUp ? 'auth.subtitle_signup' : 'auth.subtitle_login')),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: t.tr('auth.email')),
                      validator: (v) => (v == null || v.isEmpty) ? t.tr('auth.email_required') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: t.tr('auth.password'),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? t.tr('auth.password_required') : null,
                    ),
                    const SizedBox(height: 10),
                    // Zuerst: Noch kein Konto? Registrieren (zentriert)
                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp ? t.tr('auth.switch_to_login') : t.tr('auth.switch_to_signup'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Direkt darunter: Passwort vergessen? (kleiner, zentriert, weniger Abstand)
                    const SizedBox(height: 2),
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        ),
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _error = null);
                                // E-Mail automatisch vorbelegen (angemeldeter User oder Eingabefeld)
                                final currentEmail = Supabase.instance.client.auth.currentUser?.email;
                                if (currentEmail != null && currentEmail.isNotEmpty) {
                                  _emailCtrl.text = currentEmail;
                                }
                                final email = _emailCtrl.text.trim();
                                if (email.isEmpty) {
                                  setState(() => _error = t.tr('auth.email_required'));
                                  return;
                                }
                                try {
                                  setState(() => _loading = true);
                                  await Supabase.instance.client.auth.resetPasswordForEmail(
                                    email,
                                    redirectTo: 'wefixit://reset-password',
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.tr('auth.reset_email_sent'))),
                                  );
                                } on AuthException catch (e) {
                                  setState(() => _error = e.message);
                                } catch (_) {
                                  setState(() => _error = t.tr('auth.error_generic'));
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              },
                        child: Text(
                          t.tr('auth.forgot_password'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_isSignUp ? t.tr('auth.signup') : t.tr('auth.login')),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
