import 'package:flutter/material.dart';
import '../../i18n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class DiagnoseScreen extends StatelessWidget {
  const DiagnoseScreen({super.key});

  static void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anmeldung erforderlich'),
        content: const Text('Für KI-Diagnosen musst du dich anmelden. Fehlercodes auslesen und löschen ist immer kostenlos!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/auth');
            },
            child: const Text('Jetzt anmelden'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.tr('diagnose.title'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.tr('diagnose.subtitle'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildActionCard(
                    context: context,
                    icon: Icons.search,
                    iconColor: const Color(0xFFE53935),
                    iconBg: const Color(0xFFFFEBEE),
                    title: t.tr('diagnose.read_dtc'),
                    badge: t.diagnose_always_free,
                    badgeColor: const Color(0xFF4CAF50),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context: context,
                    icon: Icons.delete_sweep_outlined,
                    iconColor: const Color(0xFF1976D2),
                    iconBg: const Color(0xFFE3F2FD),
                    title: t.tr('diagnose.clear_dtc'),
                    badge: t.diagnose_always_free,
                    badgeColor: const Color(0xFF4CAF50),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context: context,
                    icon: Icons.psychology_outlined,
                    iconColor: const Color(0xFFF57C00),
                    iconBg: const Color(0xFFFFF3E0),
                    title: t.tr('diagnose.ai_diagnose'),
                    badge: t.diagnose_may_use_credits,
                    badgeColor: const Color(0xFFF57C00),
                    onTap: () {
                      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
                      if (!isLoggedIn) {
                        _showLoginRequired(context);
                      } else {
                        // TODO: Start AI Diagnosis
                      }
                    },
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Info Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.diagnose_how_it_works,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.cable,
                      title: t.diagnose_connect_adapter,
                      description: t.diagnose_connect_adapter_desc,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.bluetooth,
                      title: t.diagnose_activate_bluetooth,
                      description: t.diagnose_activate_bluetooth_desc,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.play_arrow,
                      title: t.diagnose_start_diagnosis,
                      description: t.diagnose_start_diagnosis_desc,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF616161), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

