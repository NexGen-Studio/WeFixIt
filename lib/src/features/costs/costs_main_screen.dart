import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_localizations.dart';
import '../../services/admob_service.dart';
import '../../services/costs_counter_service.dart';
import '../../services/purchase_service.dart';
import 'tabs/costs_history_tab.dart';
import 'tabs/costs_statistics_tab.dart';
import 'tabs/costs_charts_tab.dart';

/// Haupt-Screen für KFZ-Kosten mit 3 Tabs
class CostsMainScreen extends StatefulWidget {
  const CostsMainScreen({Key? key}) : super(key: key);

  @override
  State<CostsMainScreen> createState() => _CostsMainScreenState();
}

class _CostsMainScreenState extends State<CostsMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final _adMobService = AdMobService();
  final _counterService = CostsCounterService();
  final _purchaseService = PurchaseService();
  bool _showFab = true;
  int _refreshTrigger = 0;
  Timer? _hideTimer;
  Timer? _scrollTimer;
  bool _isPro = false;

  // Shared Timeframe State
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _initializeServices();
    
    // Initialize Timeframe: Current Month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime.now();

    // FAB nach 2 Sekunden initial ausblenden
    _startHideTimer();
  }

  Future<void> _initializeServices() async {
    await _adMobService.initialize();
    await _adMobService.loadRewardedAd();
    _isPro = await _purchaseService.isPro();
    if (mounted) setState(() {});
  }

  void _onDateRangeChanged(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFab = false);
      }
    });
  }

  void _onScroll() {
    // Beim Scrollen FAB anzeigen
    if (!_showFab) {
      setState(() => _showFab = true);
    }
    
    // Timer zurücksetzen: FAB nach 2 Sek ohne Scroll wieder ausblenden
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFab = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          t.tr('costs.title'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Neuen Eintrag erstellen
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFFB129), size: 28),
            onPressed: _handleNewCost,
          ),
          // Kategorien verwalten
          IconButton(
            icon: const Icon(Icons.list_alt, color: Color(0xFFFFB129)),
            onPressed: () => context.push('/costs/categories'),
          ),
          // Achievements anzeigen
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Color(0xFFFFB129)),
            onPressed: () => context.push('/costs/achievements'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFB129),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: t.tr('costs.tab_history')),
            Tab(text: t.tr('costs.tab_statistics')),
            Tab(text: t.tr('costs.tab_charts')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CostsHistoryTab(key: ValueKey('history_$_refreshTrigger'), scrollController: _scrollController),
          CostsStatisticsTab(
            key: ValueKey('statistics_$_refreshTrigger'), 
            scrollController: _scrollController,
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: _onDateRangeChanged,
          ),
          CostsChartsTab(
            key: ValueKey('charts_$_refreshTrigger'), 
            scrollController: _scrollController,
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: _onDateRangeChanged,
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showFab ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: _handleNewCost,
            backgroundColor: const Color(0xFFFFB129),
            icon: const Icon(Icons.add, color: Colors.black),
            label: Text(
              t.tr('costs.add_entry'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle new cost creation with ad gate
  Future<void> _handleNewCost() async {
    // Pro users bypass ad gate
    if (_isPro) {
      await context.push('/costs/add');
      setState(() => _refreshTrigger++);
      return;
    }

    // Check if user needs to watch ad
    final needsAd = await _counterService.needsToWatchAd();
    
    if (needsAd) {
      // Show ad gate dialog
      _showAdGateDialog();
    } else {
      // User has free slots, proceed
      await context.push('/costs/add');
      await _counterService.incrementCount();
      setState(() => _refreshTrigger++);
    }
  }

  /// Show ad gate dialog
  void _showAdGateDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.tr('costs.ad_gate_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          t.tr('costs.ad_gate_message'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.common_cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/paywall');
            },
            child: Text(
              t.tr('costs.become_pro'),
              style: const TextStyle(color: Color(0xFFFFB129)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _watchAdAndProceed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB129),
              foregroundColor: Colors.black,
            ),
            child: Text(t.tr('costs.watch_video')),
          ),
        ],
      ),
    );
  }

  /// Watch ad and proceed to cost creation
  Future<void> _watchAdAndProceed() async {
    print('\n🟢 [UI-Costs] ========== _watchAdAndProceed STARTED ==========');
    
    final router = GoRouter.of(context);

    print('🟢 [UI-Costs] Calling prepareRewardedAd()...');
    final ready = await _adMobService.prepareRewardedAd();
    print('✅ [UI-Costs] prepareRewardedAd() returned: $ready');

    if (ready) {
      print('🟢 [UI-Costs] Ad is ready, calling showRewardedAd()...');
      final success = await _adMobService.showRewardedAd();
      print('✅ [UI-Costs] showRewardedAd() RETURNED with success: $success');
      
      if (success) {
        print('🟢 [UI-Costs] User earned reward, resetting counter...');
        await _counterService.resetCount();
        print('✅ [UI-Costs] Counter reset');
        
        print('🟢 [UI-Costs] Navigating to /costs/add with saved router...');
        try {
          await router.push('/costs/add');
          print('✅ [UI-Costs] Navigation completed!');
          
          print('🟢 [UI-Costs] Incrementing counter...');
          await _counterService.incrementCount();
          setState(() => _refreshTrigger++);
          print('✅ [UI-Costs] All done!');
        } catch (e) {
          print('❌ [UI-Costs] Navigation error: $e');
        }
      } else {
        print('⚠️ [UI-Costs] Ad did not succeed (user cancelled or error)');
      }
    } else {
      print('❌ [UI-Costs] Ad NOT ready!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Werbung konnte nicht geladen werden. Bitte versuche es später erneut.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🟢 [UI-Costs] ========== _watchAdAndProceed FINISHED ==========\n');
  }
}
