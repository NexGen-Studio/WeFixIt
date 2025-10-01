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
  String? _vehiclePhotoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = SupabaseService(Supabase.instance.client);
    final p = await svc.fetchUserProfile();
    if (!mounted) return;
    setState(() {
      _displayCtrl.text = p?.displayName ?? '';
      _firstCtrl.text = p?.firstName ?? '';
      _lastCtrl.text = p?.lastName ?? '';
      _avatarUrl = p?.avatarUrl;
      _vehiclePhotoUrl = p?.vehiclePhotoUrl;
    });
  }

  Future<void> _pickVehiclePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final svc = SupabaseService(Supabase.instance.client);
    final url = await svc.uploadVehiclePhoto(picked.path);
    if (url != null) {
      setState(() => _vehiclePhotoUrl = url);
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
      vehiclePhotoUrl: _vehiclePhotoUrl,
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
        foregroundColor: Colors.white,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          _GlassCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.tr('profile.account'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Text(Supabase.instance.client.auth.currentUser?.email ?? '', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(t.tr('profile.manage_subscription'), style: const TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Großes Fahrzeugbild (falls vorhanden)
          if ((_vehiclePhotoUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_vehiclePhotoUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          if ((_vehiclePhotoUrl ?? '').isNotEmpty) const SizedBox(height: 12),
          _GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profil', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
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
                          label: 'Fahrzeugfoto wählen',
                          onPressed: _pickVehiclePhoto,
                        ),
                      ),
                    ],
                  ),
                  if (_vehiclePhotoUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_vehiclePhotoUrl!, height: 80, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _GlassButton(label: _saving ? 'Speichern…' : 'Speichern', onPressed: _saving ? null : _save),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Fahrzeugdaten bearbeiten
          _GlassCard(
            child: _VehicleForm(),
          ),
          const SizedBox(height: 12),
          // Tabs: Letzte Diagnosen / Letzte Chats (Platzhalter)
          _GlassCard(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(labelColor: Colors.white, tabs: [Tab(text: 'Diagnosen'), Tab(text: 'Chats')]),
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
        color: const Color(0xFF008CFF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white70),
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
        backgroundColor: const Color(0xFF4A4A4A),
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
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _engine = TextEditingController();
  final _displCc = TextEditingController();
  final _displL = TextEditingController();
  final _mileage = TextEditingController();
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
      _displL.text = (v?['displacement_l']?.toString() ?? '');
      _mileage.text = (v?['mileage_km']?.toString() ?? '');
      _loading = false;
    });
  }

  Future<void> _save() async {
    final svc = SupabaseService(Supabase.instance.client);
    await svc.savePrimaryVehicle({
      'make': _make.text.trim(),
      'model': _model.text.trim(),
      'year': int.tryParse(_year.text.trim()),
      'engine_code': _engine.text.trim(),
      'displacement_cc': int.tryParse(_displCc.text.trim()),
      'displacement_l': double.tryParse(_displL.text.trim()),
      'mileage_km': int.tryParse(_mileage.text.trim()),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fahrzeug gespeichert')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fahrzeugdaten', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        _GlassField(controller: _make, label: 'Marke'),
        const SizedBox(height: 8),
        _GlassField(controller: _model, label: 'Modell'),
        const SizedBox(height: 8),
        _GlassField(controller: _year, label: 'Baujahr (YYYY)'),
        const SizedBox(height: 8),
        _GlassField(controller: _engine, label: 'Motorcode'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _GlassField(controller: _displCc, label: 'Hubraum (cc)')),
          const SizedBox(width: 8),
          Expanded(child: _GlassField(controller: _displL, label: 'Hubraum (L)')),
        ]),
        const SizedBox(height: 8),
        _GlassField(controller: _mileage, label: 'Kilometerstand (km)'),
        const SizedBox(height: 12),
        _GlassButton(label: _loading ? 'Laden…' : 'Fahrzeug speichern', onPressed: _loading ? null : _save),
      ],
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
        ListTile(title: Text('Letzte $kind 1', style: const TextStyle(color: Colors.white))),
        ListTile(title: Text('Letzte $kind 2', style: const TextStyle(color: Colors.white))),
        ListTile(title: Text('Letzte $kind 3', style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}
