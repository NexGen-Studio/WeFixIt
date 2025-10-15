import 'package:flutter/material.dart';
import '../../i18n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/profile.dart';
import '../../state/locale_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String? _avatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showImagePreview(String url) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 32,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _load() async {
    final svc = SupabaseService(Supabase.instance.client);
    final p = await svc.fetchUserProfile();
    if (!mounted) return;
    String? avatarUrlUi;
    if ((p?.avatarUrl ?? '').isNotEmpty) {
      // p.avatarUrl enthält bei privaten Buckets den Storage-Key
      avatarUrlUi = await svc.getSignedAvatarUrl(p!.avatarUrl!);
    }
    setState(() {
      _displayCtrl.text = p?.displayName ?? '';
      _firstCtrl.text = p?.firstName ?? '';
      _lastCtrl.text = p?.lastName ?? '';
      _avatarUrl = avatarUrlUi ?? p?.avatarUrl; // bevorzugt signierte URL
      // vehiclePhotoUrl wird nicht mehr im Profilbereich angezeigt
    });
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final svc = SupabaseService(Supabase.instance.client);
    final url = await svc.uploadAvatarPhoto(picked.path);
    if (url != null) {
      setState(() => _avatarUrl = url);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = SupabaseService(Supabase.instance.client);
    final user = Supabase.instance.client.auth.currentUser;
    final profile = UserProfile(
      id: user!.id,
      displayName: _displayCtrl.text.trim().isEmpty ? null : _displayCtrl.text.trim(),
      firstName: _firstCtrl.text.trim().isNotEmpty ? _firstCtrl.text.trim() : null,
      lastName: _lastCtrl.text.trim().isNotEmpty ? _lastCtrl.text.trim() : null,
      avatarUrl: _avatarUrl,
    );
    await svc.saveUserProfile(profile);
    // Reload to ensure UI reflects DB
    await _load();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil gespeichert')));
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF636564),
        title: Text(t.tr('profile.title')),
        actions: [
          IconButton(onPressed: () { context.go('/settings'); }, icon: const Icon(Icons.settings)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Anzeigename oben links
          if (_displayCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                _displayCtrl.text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF636564), fontWeight: FontWeight.w700),
              ),
            ),
          _GlassCard(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final url = _avatarUrl;
                    if (url != null && url.isNotEmpty) _showImagePreview(url);
                  },
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    backgroundImage: (_avatarUrl ?? '').isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                    child: (_avatarUrl ?? '').isNotEmpty ? null : const Icon(Icons.person, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.tr('profile.account'), style: const TextStyle(color: Color(0xFF636564), fontWeight: FontWeight.w600)),
                      Text(Supabase.instance.client.auth.currentUser?.email ?? '', style: const TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickAvatar,
                  child: const Text('Profilbild wählen', style: TextStyle(color: Color(0xFF2563EB))),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                collapsedIconColor: const Color(0xFF636564),
                iconColor: const Color(0xFF636564),
                title: Text('Profil', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF636564))),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GlassField(
                          controller: _displayCtrl,
                          label: 'Anzeigename',
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _GlassField(controller: _firstCtrl, label: 'Vorname')),
                          const SizedBox(width: 8),
                          Expanded(child: _GlassField(controller: _lastCtrl, label: 'Nachname')),
                        ]),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _GlassButton(
                                label: 'Profilbild wählen',
                                onPressed: _pickAvatar,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _GlassButton(label: _saving ? 'Speichern…' : 'Speichern', onPressed: _saving ? null : _save),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Fahrzeugdaten bearbeiten (einklappbar)
          _GlassCard(child: _VehicleForm()),
          const SizedBox(height: 12),
          // Tabs: Letzte Diagnosen / Letzte Chats (Platzhalter)
          _GlassCard(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(labelColor: Color(0xFF636564), unselectedLabelColor: Color(0xFF94A3B8), tabs: [Tab(text: 'Diagnosen'), Tab(text: 'Ask Toni!')]),
                  SizedBox(
                    height: 160,
                    child: TabBarView(
                      children: [
                        _LastListPlaceholder(kind: 'Diagnose'),
                        _LastListPlaceholder(kind: 'Chat'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({required this.controller, required this.label, this.validator, this.keyboardType});
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF636564)),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _engine = TextEditingController();
  final _displCc = TextEditingController();
  final _mileage = TextEditingController();
  final _power = TextEditingController();
  bool _powerIsKw = true; // toggle kW/PS, stored as kW
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = SupabaseService(Supabase.instance.client);
    final v = await svc.fetchPrimaryVehicle();
    if (!mounted) return;
    setState(() {
      _make.text = (v?['make'] ?? '') as String;
      _model.text = (v?['model'] ?? '') as String;
      _year.text = (v?['year']?.toString() ?? '');
      _engine.text = (v?['engine_code'] ?? '') as String;
      _displCc.text = (v?['displacement_cc']?.toString() ?? '');
      _mileage.text = (v?['mileage_km']?.toString() ?? '');
      final kw = (v?['power_kw'] as int?) ?? 0;
      _power.text = kw == 0 ? '' : kw.toString();
      _powerIsKw = true;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final svc = SupabaseService(Supabase.instance.client);
    // normalize power to kW
    int? powerKw;
    final p = int.tryParse(_power.text.trim());
    if (p != null) {
      powerKw = _powerIsKw ? p : (p * 0.7355).round();
    }
    await svc.savePrimaryVehicle({
      'make': _make.text.trim(),
      'model': _model.text.trim(),
      'year': int.tryParse(_year.text.trim()),
      'engine_code': _engine.text.trim(),
      'displacement_cc': int.tryParse(_displCc.text.trim()),
      'power_kw': powerKw,
      'mileage_km': int.tryParse(_mileage.text.trim()),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fahrzeug gespeichert')));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        collapsedIconColor: const Color(0xFF636564),
        iconColor: const Color(0xFF636564),
        title: Text('Fahrzeugdaten', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF636564))),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GlassField(
                  controller: _make,
                  label: 'Marke',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                ),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _model,
                  label: 'Modell',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                ),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _year,
                  label: 'Baujahr (YYYY)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Pflichtfeld';
                    final y = int.tryParse(v.trim());
                    final now = DateTime.now().year;
                    if (y == null || y < 1886 || y > now) return 'Ungültiges Jahr';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _GlassField(controller: _engine, label: 'Motorcode'),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _displCc,
                  label: 'Hubraum (cc)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final cc = int.tryParse(v.trim());
                    if (cc == null || cc < 50 || cc > 10000) return '50–10000 cc';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _GlassField(
                      controller: _power,
                      label: _powerIsKw ? 'Leistung (kW)' : 'Leistung (PS)',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null; // optional
                        final p = int.tryParse(v.trim());
                        if (p == null || p <= 0) return 'Wert > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UnitSwitch(
                    isKw: _powerIsKw,
                    onChanged: (val) {
                      setState(() => _powerIsKw = val);
                    },
                  ),
                ]),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _mileage,
                  label: 'Kilometerstand (km)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final km = int.tryParse(v.trim());
                    if (km == null || km < 0) return 'km ≥ 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _GlassButton(
                  label: _loading ? 'Laden…' : 'Fahrzeug speichern',
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _save();
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitSwitch extends StatelessWidget {
  const _UnitSwitch({required this.isKw, required this.onChanged});
  final bool isKw;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => onChanged(true),
            child: Text('kW', style: TextStyle(color: isKw ? const Color(0xFF2563EB) : const Color(0xFF94A3B8))),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => onChanged(false),
            child: Text('PS', style: TextStyle(color: !isKw ? const Color(0xFF2563EB) : const Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }
}

class _LastListPlaceholder extends StatelessWidget {
  const _LastListPlaceholder({required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(title: Text('Letzte $kind 1', style: const TextStyle(color: Color(0xFF636564)))),
        ListTile(title: Text('Letzte $kind 2', style: const TextStyle(color: Color(0xFF636564)))),
        ListTile(title: Text('Letzte $kind 3', style: const TextStyle(color: Color(0xFF636564)))),
      ],
    );
  }
}
