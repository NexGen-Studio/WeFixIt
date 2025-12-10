import 'dart:convert';

import 'package:flutter/material.dart';
import '../../i18n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/profile.dart';
import '../../state/locale_provider.dart';
import '../../state/profile_controller.dart';
import 'package:go_router/go_router.dart';
import '../../services/credit_service.dart';
import '../../services/purchase_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<_VehicleFormState>();
  final _displayCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String? _avatarKey;  // Storage key (wird in DB gespeichert)
  String? _avatarUrlUi;  // Signierte URL (nur für UI)
  String? _vehiclePhotoUrl;  // Vehicle photo URL (persisted)
  String? _vehiclePhotoUrlUi;  // Vehicle photo URL für UI (mit Cache-Busting)
  bool _saving = false;
  bool _avatarDeleting = false;
  bool _vehicleDeleting = false;
  void Function()? _profileListenerDispose;
  bool _profileHydrated = false;
  String? _lastProfileSignature;
  
  // Credits & Free Quota
  int _creditBalance = 0;
  int _freeQuotaConsumed = 0;
  DateTime? _weekStartDate;
  bool _loadingCredits = true;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCreditsInfo();
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

  String _cacheBustUrl(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}cb=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _load() async {
    final svc = SupabaseService(Supabase.instance.client);
    final p = await svc.fetchUserProfile();
    if (!mounted) return;
    String? avatarUrlUi;
    if ((p?.avatarUrl ?? '').isNotEmpty) {
      // p.avatarUrl enthält den Storage-Key
      avatarUrlUi = await svc.getSignedAvatarUrl(p!.avatarUrl!);
    }
    final vehiclePhoto = p?.vehiclePhotoUrl;
    setState(() {
      _displayCtrl.text = p?.displayName ?? '';
      _firstCtrl.text = p?.firstName ?? '';
      _lastCtrl.text = p?.lastName ?? '';
      _avatarKey = p?.avatarUrl;  // Speichere Key
      _avatarUrlUi = avatarUrlUi;  // Speichere signierte URL für UI
      _vehiclePhotoUrl = vehiclePhoto;  // Vehicle photo URL
      _vehiclePhotoUrlUi = (vehiclePhoto != null && vehiclePhoto.isNotEmpty) ? _cacheBustUrl(vehiclePhoto) : null;
    });
  }

  Future<void> _loadCreditsInfo() async {
    setState(() => _loadingCredits = true);
    try {
      final creditService = CreditService();
      final purchaseService = PurchaseService();
      
      // Load credit balance
      final balance = await creditService.getCreditBalance();
      
      // Load free quota info
      final quotaInfo = await creditService.getFreeQuotaInfo();
      
      // Check Pro status
      final isPro = await purchaseService.isPro();
      
      if (!mounted) return;
      setState(() {
        _creditBalance = balance;
        _freeQuotaConsumed = quotaInfo['consumed'] ?? 0;
        _weekStartDate = quotaInfo['weekStartDate'];
        _isPro = isPro;
        _loadingCredits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCredits = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null || !mounted) return;
    final svc = SupabaseService(Supabase.instance.client);
    final result = await svc.uploadAvatarPhoto(picked.path);
    if (result != null) {
      // result ist die signierte URL, wir brauchen aber den Key
      final user = Supabase.instance.client.auth.currentUser;
      final key = 'avatar_${user!.id}.jpg';
      setState(() {
        _avatarKey = key;
        _avatarUrlUi = result;  // Verwende signierte URL für sofortige Anzeige
      });
    }
  }

  Future<void> _deleteAvatar() async {
    if ((_avatarKey ?? '').isEmpty && (_avatarUrlUi ?? '').isEmpty) return;
    setState(() => _avatarDeleting = true);
    final svc = SupabaseService(Supabase.instance.client);
    await svc.deleteAvatarPhoto();
    if (!mounted) return;
    setState(() {
      _avatarDeleting = false;
      _avatarKey = null;
      _avatarUrlUi = null;
    });
    await _load();
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tr('profile.avatar_deleted'))));
  }

  Future<void> _pickVehiclePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;

    final t = AppLocalizations.of(context);

    // Calculate aspect ratio to match Home display: width = 90% of screen, height = 100 px
    final screenWidth = MediaQuery.of(context).size.width;
    final displayWidth = screenWidth * 0.9;
    final displayHeight = 140.0; // etwas höherer Ausschnitt

    // Use ImageCropper to let user pan/zoom within a fixed aspect ratio frame
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: CropAspectRatio(ratioX: displayWidth, ratioY: displayHeight),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: t.tr('profile.crop_title'),
          toolbarColor: const Color(0xFF0F141A),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFF8AD20),
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
          backgroundColor: const Color(0xFF0F141A),
          dimmedLayerColor: Colors.black.withOpacity(0.6),
        ),
        IOSUiSettings(
          title: t.tr('profile.crop_title'),
          aspectRatioLockEnabled: true,
          rotateButtonsHidden: true,
          resetAspectRatioEnabled: false,
        ),
      ],
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
    );

    final pathToUpload = cropped?.path ?? picked.path; // fallback if user cancels crop

    final svc = SupabaseService(Supabase.instance.client);
    final result = await svc.uploadVehiclePhoto(pathToUpload);
    if (result != null) {
      if (mounted) {
        setState(() {
          _vehiclePhotoUrl = result;
          _vehiclePhotoUrlUi = _cacheBustUrl(result);
        });
      }
      await _load(); // Reload to ensure UI reflects DB
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tr('profile.vehicle_photo_uploaded'))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tr('common.upload_error'))));
    }
  }

  Future<void> _deleteVehiclePhoto() async {
    if ((_vehiclePhotoUrl ?? '').isEmpty && (_vehiclePhotoUrlUi ?? '').isEmpty) return;
    setState(() => _vehicleDeleting = true);
    final svc = SupabaseService(Supabase.instance.client);
    await svc.deleteVehiclePhoto();
    if (!mounted) return;
    setState(() {
      _vehicleDeleting = false;
      _vehiclePhotoUrl = null;
      _vehiclePhotoUrlUi = null;
    });
    await _load();
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tr('profile.vehicle_photo_deleted'))));
  }

  Future<void> _useAvatarAsVehicle() async {
    final t = AppLocalizations.of(context);
    if ((_avatarKey ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tr('profile.upload_avatar_first'))));
      return;
    }
    final svc = SupabaseService(Supabase.instance.client);
    final result = await svc.copyAvatarToVehiclePhoto();
    if (result != null) {
      if (mounted) {
        setState(() {
          _vehiclePhotoUrl = result;
          _vehiclePhotoUrlUi = _cacheBustUrl(result);
        });
      }
      await _load(); // Reload to ensure UI reflects DB
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tr('profile.copied_as_vehicle'))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.tr('profile.copy_error'))));
    }
  }

  Future<void> _save() async {
    final svc = SupabaseService(Supabase.instance.client);
    final user = Supabase.instance.client.auth.currentUser;
    final firstNameValue = _firstCtrl.text.trim();
    final lastNameValue = _lastCtrl.text.trim();
    final profile = UserProfile(
      id: user!.id,
      displayName: _displayCtrl.text.trim(),
      firstName: firstNameValue.isNotEmpty ? firstNameValue : '',
      lastName: lastNameValue.isNotEmpty ? lastNameValue : '',
      avatarUrl: _avatarKey,  // Speichere nur den Key in der DB!
      vehiclePhotoUrl: _vehiclePhotoUrl,  // Vehicle photo URL
    );
    await svc.saveUserProfile(profile);
    // Reload to ensure UI reflects DB
    await _load();
  }

  Future<void> _saveAll() async {
    // Validiere Vehicle Form nur wenn ExpansionTile geöffnet und Felder ausgefüllt
    final vehicleValid = _vehicleFormKey.currentState?.validateForm() ?? true;
    
    if (!vehicleValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Marke und Modell ausfüllen')),
      );
      return;
    }

    setState(() => _saving = true);
    
    try {
      // Speichere Profil
      await _save();
      // Speichere Fahrzeugdaten
      await _vehicleFormKey.currentState?.saveVehicle();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil und Fahrzeugdaten gespeichert')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    // Wenn nicht eingeloggt, zeige Login-CTA
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1117),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF151C23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => context.go('/settings'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Login-CTA Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151C23),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB129).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 48,
                            color: Color(0xFFFFB129),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t.profile_please_login,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.profile_login_message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/auth'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              t.profile_login_now,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),  
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      );
    }

    // Normaler Profil-Screen für eingeloggte User
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFFB129),
          backgroundColor: const Color(0xFF151C23),
          onRefresh: () async {
            await Future.wait([
              _load(),
              _loadCreditsInfo(),
            ]);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayCtrl.text.isNotEmpty ? _displayCtrl.text : t.tr('profile.title'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Supabase.instance.client.auth.currentUser?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C23),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => context.go('/settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Credits & Free Quota Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _loadingCredits
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151C23),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151C23),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB129).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _isPro ? Icons.workspace_premium : Icons.star_outline,
                                    color: const Color(0xFFFFB129),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isPro ? t.credits_pro_member : t.credits_title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (!_isPro) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          t.creditsRemaining(3 - _freeQuotaConsumed),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!_isPro) ...[
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.credits_my_credits,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.monetization_on, color: const Color(0xFFFFB129), size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$_creditBalance',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => context.push('/paywall'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB129),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(
                                      t.credits_buy,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              if (_weekStartDate != null) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    t.credits_quota_renews_weekly,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            if (_isPro) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.greenAccent[100], size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t.credits_unlimited_ai,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.95),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),

            // Profil-Karte
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151C23),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final url = _avatarUrlUi;
                                  if (url != null && url.isNotEmpty) _showImagePreview(url);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.transparent,
                                    foregroundImage: (_avatarUrlUi ?? '').isNotEmpty
                                        ? NetworkImage(_avatarUrlUi!)
                                        : null,
                                    child: (_avatarUrlUi ?? '').isNotEmpty
                                        ? null
                                        : const Icon(Icons.person_outline, color: Colors.white54, size: 28),
                                  ),
                                ),
                              ),
                              if ((_avatarUrlUi ?? '').isNotEmpty)
                                Positioned(
                                  top: -14,
                                  right: -14,
                                  child: IconButton(
                                    constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                                    padding: EdgeInsets.zero,
                                    onPressed: _avatarDeleting ? null : _deleteAvatar,
                                    tooltip: AppLocalizations.of(context).tr('profile.remove_avatar'),
                                    icon: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFE53935),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: _avatarDeleting
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.profile_profile_picture,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.profile_click_to_change,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _pickAvatar,
                            icon: const Icon(Icons.edit, color: Color(0xFFF8AD20)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlassCard(
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                          collapsedIconColor: Colors.white,
                          iconColor: Colors.white,
                          title: Text(
                            t.profile_edit_profile,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GlassField(
                          controller: _displayCtrl,
                          label: t.profile_display_name,
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _GlassField(controller: _firstCtrl, label: t.profile_first_name)),
                          const SizedBox(width: 8),
                          Expanded(child: _GlassField(controller: _lastCtrl, label: t.profile_last_name)),
                        ]),
                        const SizedBox(height: 8),
                        // Vehicle photo section
                        Row(
                          children: [
                            Expanded(
                              child: _GlassButton(
                                label: t.tr('profile.choose_vehicle_photo'),
                                onPressed: _pickVehiclePhoto,
                              ),
                            ),
                          ],
                        ),
                        if ((_vehiclePhotoUrlUi ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final previewUrl = _vehiclePhotoUrlUi ?? _vehiclePhotoUrl;
                                    if (previewUrl != null && previewUrl.isNotEmpty) {
                                      _showImagePreview(previewUrl);
                                    }
                                  },
                                  child: Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!, width: 1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(_vehiclePhotoUrlUi!, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -12,
                                  right: -12,
                                  child: IconButton(
                                    constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                                    padding: EdgeInsets.zero,
                                    onPressed: _vehicleDeleting ? null : _deleteVehiclePhoto,
                                    tooltip: t.tr('profile.remove_vehicle_photo'),
                                    icon: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFE53935),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: _vehicleDeleting
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
                    ),
                    const SizedBox(height: 12),
                    // Fahrzeugdaten bearbeiten (einklappbar)
                    _GlassCard(child: _VehicleForm(key: _vehicleFormKey)),
                    const SizedBox(height: 12),
                    // Gemeinsamer Speichern Button
                    SizedBox(
                      width: double.infinity,
                      child: _saving
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _saveAll,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                t.profile_save,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    // Tabs: Letzte Diagnosen / Letzte Chats (Platzhalter)
                    _GlassCard(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white54,
                              tabs: [
                                Tab(text: t.profile_diagnoses),
                                Tab(text: 'Ask Toni!'),
                              ],
                            ),
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
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
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white54),
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
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm({super.key});
  
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
  String? _vehicleId;

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
      _vehicleId = (v?['id'] ?? v?['vehicle_id'])?.toString();
      _make.text = (v?['make'] ?? '') as String;
      _model.text = (v?['model'] ?? '') as String;
      _year.text = (v?['year']?.toString() ?? '');
      _engine.text = (v?['engine_code'] ?? '') as String;
      _displCc.text = (v?['displacement_cc']?.toString() ?? '');
      _mileage.text = (v?['mileage_km']?.toString() ?? '');
      final kw = (v?['power_kw'] as int?) ?? 0;
      // Konvertiere kW zu PS beim Laden (üblicher in Deutschland)
      final ps = kw == 0 ? 0 : (kw * 1.36).round();
      _power.text = ps == 0 ? '' : ps.toString();
      _powerIsKw = false; // Zeige PS an
      _loading = false;
    });
  }

  // Public Methoden für externen Zugriff
  bool validateForm() {
    final formState = _formKey.currentState;
    if (formState == null) return true;
    return formState.validate();
  }

  Future<void> saveVehicle() async {
    await _save();
  }

  Future<void> _save() async {
    final svc = SupabaseService(Supabase.instance.client);
    // normalize power to kW
    int? powerKw;
    final p = int.tryParse(_power.text.trim());
    if (p != null) {
      powerKw = _powerIsKw ? p : (p * 0.7355).round();
    }
    final payload = <String, dynamic>{
      if (_vehicleId != null && _vehicleId!.isNotEmpty) 'id': _vehicleId,
      'make': _make.text.trim(),
      'model': _model.text.trim(),
      'year': int.tryParse(_year.text.trim()),
      'engine_code': _engine.text.trim(),
      'displacement_cc': int.tryParse(_displCc.text.trim()),
      'power_kw': powerKw,
      'mileage_km': int.tryParse(_mileage.text.trim()),
    };

    final saved = await svc.savePrimaryVehicle(payload);
    if (saved != null && mounted) {
      setState(() {
        _vehicleId = (saved['id'] ?? saved['vehicle_id'])?.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        title: Text(t.profile_vehicle_data, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GlassField(
                  controller: _make,
                  label: t.profile_make,
                  validator: (v) => (v == null || v.trim().isEmpty) ? t.profile_required : null,
                ),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _model,
                  label: t.profile_model,
                  validator: (v) => (v == null || v.trim().isEmpty) ? t.profile_required : null,
                ),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _year,
                  label: t.profile_year,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return t.profile_required;
                    final y = int.tryParse(v.trim());
                    final now = DateTime.now().year;
                    if (y == null || y < 1886 || y > now) return 'Ungültiges Jahr';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _GlassField(controller: _engine, label: t.profile_engine_code),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _displCc,
                  label: t.profile_displacement,
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
                      setState(() {
                        // Umrechnung nur wenn Wert vorhanden
                        final currentText = _power.text.trim();
                        if (currentText.isNotEmpty) {
                          final currentValue = int.tryParse(currentText);
                          if (currentValue != null && currentValue > 0) {
                            if (val && !_powerIsKw) {
                              // Wechsel von PS zu kW
                              final kw = (currentValue / 1.36).round();
                              _power.text = kw.toString();
                            } else if (!val && _powerIsKw) {
                              // Wechsel von kW zu PS
                              final ps = (currentValue * 1.36).round();
                              _power.text = ps.toString();
                            }
                          }
                        }
                        _powerIsKw = val;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 8),
                _GlassField(
                  controller: _mileage,
                  label: t.profile_mileage,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final km = int.tryParse(v.trim());
                    if (km == null || km < 0) return 'km ≥ 0';
                    return null;
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
            child: Text('kW', style: TextStyle(color: isKw ? const Color(0xFFFFB129) : const Color(0xFF94A3B8))),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => onChanged(false),
            child: Text('PS', style: TextStyle(color: !isKw ? const Color(0xFFFFB129) : const Color(0xFF94A3B8))),
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
    final t = AppLocalizations.of(context);
    return ListView(
      children: [
        ListTile(title: Text(t.profile_last_item.replaceAll('{kind}', kind).replaceAll('{number}', '1'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ListTile(title: Text(t.profile_last_item.replaceAll('{kind}', kind).replaceAll('{number}', '2'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ListTile(title: Text(t.profile_last_item.replaceAll('{kind}', kind).replaceAll('{number}', '3'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
