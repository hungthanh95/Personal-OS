import 'dart:async';

import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/modern_screens.dart';
import 'screens/today_overview_screen.dart';
import 'screens/utilities.dart';

class AppShell extends StatefulWidget {
  final AppController app;
  final String databasePath;
  final Future<void> Function(String path)? onRestore;
  const AppShell(this.app, this.databasePath, {this.onRestore, super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selected = 0;
  Timer? clock;
  DateTime? lastReconciliation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
      final now = DateTime.now();
      final endedSession = widget.app.workspace.sessions.any((session) {
        final end = session.plannedStart.add(
          Duration(minutes: session.plannedMinutes),
        );
        return !session.status.terminal &&
            !end.isAfter(now) &&
            (lastReconciliation == null || end.isAfter(lastReconciliation!));
      });
      final hasDueSessionWaiting = widget.app.workspace.sessions.any(
        (session) => session.isDue(now) && !session.status.terminal,
      );
      if (endedSession ||
          (hasDueSessionWaiting &&
              (lastReconciliation == null ||
                  now.difference(lastReconciliation!).inMinutes >= 5))) {
        _reconcile();
      }
    });
    if (widget.databasePath != 'test.sqlite' &&
        widget.app.workspace.settings['onboarding_complete'] != 'true') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showOnboarding(context, widget.app, firstRun: true);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reconcile();
  }

  Future<void> _reconcile() async {
    if (widget.app.reconciling) return;
    lastReconciliation = DateTime.now();
    try {
      await widget.app.reconcileSessions();
    } catch (_) {
      // AppController exposes the actionable error in the shell banner.
    }
  }

  void go(int index) => setState(() => selected = index);

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final pages = [
      DashboardScreen(
        app,
        onToday: () => go(1),
        onMission: () => go(2),
        onProjects: () => go(3),
        onKnowledge: () => go(5),
      ),
      TodayOverviewScreen(app),
      MissionOverviewScreen(app),
      ProjectsOverviewScreen(app),
      StrategyOverviewScreen(app),
      KnowledgeOverviewScreen(app),
      ReviewOverviewScreen(app),
      InboxScreen(app),
      SettingsOverviewScreen(
        app,
        widget.databasePath,
        onRestore: widget.onRestore,
      ),
    ];
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        width: 288,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(),
        child: SafeArea(child: _sidebar(false, drawerMode: true)),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 560;
            final compact = constraints.maxWidth < 900;
            return Row(
              children: [
                if (!narrow) _sidebar(compact),
                Expanded(
                  child: Column(
                    children: [
                      _topBar(compact, showMenu: narrow),
                      if (app.error != null)
                        MaterialBanner(
                          content: Text(app.error!),
                          actions: [
                            TextButton(
                              onPressed: () => app.refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      Expanded(
                        child: IndexedStack(index: selected, children: pages),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sidebar(bool compact, {bool drawerMode = false}) {
    final scheme = Theme.of(context).colorScheme;
    const workspace = [
      (0, 'Dashboard', Icons.space_dashboard_outlined),
      (1, 'Today', Icons.today_outlined),
      (2, 'Missions', Icons.flag_outlined),
      (3, 'Projects', Icons.folder_outlined),
    ];
    const insight = [
      (4, 'Strategy', Icons.account_tree_outlined),
      (5, 'Knowledge', Icons.auto_stories_outlined),
      (6, 'Review', Icons.fact_check_outlined),
    ];
    return Container(
      width: drawerMode ? double.infinity : (compact ? 78 : 236),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: drawerMode
            ? null
            : Border(
                right: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: .8),
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 22 : 18, 20, 14, 18),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, const Color(0xff7456b8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: .2),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.track_changes_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'PERSONAL OS',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .55,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                if (!compact) _navSectionLabel('Workspace'),
                for (final item in workspace)
                  _nav(
                    item.$1,
                    item.$2,
                    item.$3,
                    compact,
                    closeDrawer: drawerMode,
                  ),
                const SizedBox(height: 12),
                if (!compact) _navSectionLabel('Reflect & grow'),
                for (final item in insight)
                  _nav(
                    item.$1,
                    item.$2,
                    item.$3,
                    compact,
                    closeDrawer: drawerMode,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: scheme.outlineVariant),
          ),
          _nav(
            7,
            'Inbox',
            Icons.inbox_outlined,
            compact,
            closeDrawer: drawerMode,
          ),
          _nav(
            8,
            'Settings',
            Icons.settings_outlined,
            compact,
            closeDrawer: drawerMode,
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: .58),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: scheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Private · stored locally',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _navSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 7),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.15,
      ),
    ),
  );

  Widget _topBar(bool compact, {required bool showMenu}) {
    final scheme = Theme.of(context).colorScheme;
    final name = widget.app.workspace.settings['name']?.trim() ?? '';
    final unread = widget.app.workspace.inbox
        .where((item) => !item.processed)
        .length;
    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .45),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenu) ...[
            IconButton(
              tooltip: 'Open navigation',
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => showSearchPalette(context, widget.app),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20),
                      const SizedBox(width: 10),
                      if (!compact)
                        Expanded(
                          child: Text(
                            'Search missions, projects and knowledge',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        )
                      else
                        const Spacer(),
                      if (!compact)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            'Ctrl K',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: IconButton(
              tooltip: 'Inbox',
              onPressed: () => go(7),
              icon: const Icon(Icons.notifications_none),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => go(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    name.isEmpty ? 'ME' : name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(
    int index,
    String label,
    IconData icon,
    bool compact, {
    bool closeDrawer = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    child: Semantics(
      button: true,
      selected: selected == index,
      label: '$label navigation',
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected == index
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () {
                go(index);
                if (closeDrawer) scaffoldKey.currentState?.closeDrawer();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 17 : 13,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 21,
                      color: selected == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 13),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: selected == index
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (index == 7 &&
                          widget.app.workspace.inbox.any(
                            (item) => !item.processed,
                          )) ...[
                        const Spacer(),
                        Text(
                          '${widget.app.workspace.inbox.where((item) => !item.processed).length}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
