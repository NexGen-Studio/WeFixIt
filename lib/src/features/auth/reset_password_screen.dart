import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pass1Ctrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _show1 = false;
  bool _show2 = false;

  @override
  void dispose() {
    _pass1Ctrl.dispose();
    _pass2Ctrl.dispose();
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
      final newPass = _pass1Ctrl.text;
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tr('auth.password_reset_success'))),
      );
      context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = t.tr('auth.error_generic'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.tr('auth.reset_password'))),
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
                    Text(t.tr('auth.reset_password_hint')),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pass1Ctrl,
                      obscureText: !_show1,
                      decoration: InputDecoration(
                        labelText: t.tr('auth.new_password'),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _show1 = !_show1),
                          icon: Icon(_show1 ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? t.tr('auth.password_required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass2Ctrl,
                      obscureText: !_show2,
                      decoration: InputDecoration(
                        labelText: t.tr('auth.confirm_password'),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _show2 = !_show2),
                          icon: Icon(_show2 ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) => (v != _pass1Ctrl.text)
                          ? t.tr('auth.password_mismatch')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(t.tr('auth.save_new_password')),
                    ),
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
