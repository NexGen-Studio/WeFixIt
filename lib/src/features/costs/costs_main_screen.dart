import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_localizations.dart';
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
  bool _showFab = true;
  int _refreshTrigger = 0;
  Timer? _hideTimer;
  Timer? _scrollTimer;

  // Shared Timeframe State
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Initialize Timeframe: Current Month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime.now();

    // FAB nach 2 Sekunden initial ausblenden
    _startHideTimer();
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
            onPressed: () async {
              await context.push('/costs/add');
              setState(() => _refreshTrigger++);
            },
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
            onPressed: () async {
              await context.push('/costs/add');
              setState(() => _refreshTrigger++);
            },
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
}
