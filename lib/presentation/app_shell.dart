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

class _AppShellState extends State<AppShell> {
  int selected = 0;
  Timer? clock;

  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
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
    clock?.cancel();
    super.dispose();
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 820;
            return Row(
              children: [
                _sidebar(compact),
                Expanded(
                  child: Column(
                    children: [
                      _topBar(compact),
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

  Widget _sidebar(bool compact) {
    final scheme = Theme.of(context).colorScheme;
    const primary = [
      (0, 'Dashboard', Icons.space_dashboard_outlined),
      (2, 'Missions', Icons.flag_outlined),
      (3, 'Projects', Icons.folder_outlined),
      (4, 'Strategy', Icons.account_tree_outlined),
      (5, 'Knowledge', Icons.auto_stories_outlined),
      (6, 'Review', Icons.fact_check_outlined),
    ];
    return Container(
      width: compact ? 78 : 220,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .55),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 22 : 20, 24, 14, 22),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff3978e6), Color(0xff6b5fce)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.blur_on,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'PERSONAL OS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .65,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!compact)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'MISSION CONTROL',
                style: TextStyle(fontSize: 9, letterSpacing: 1.25),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                for (final item in primary)
                  _nav(item.$1, item.$2, item.$3, compact),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: scheme.outlineVariant),
          ),
          _nav(7, 'Inbox', Icons.inbox_outlined, compact),
          _nav(8, 'Settings', Icons.settings_outlined, compact),
          if (!compact)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: Text(
                'Intention → Evidence',
                style: TextStyle(fontSize: 11),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _topBar(bool compact) {
    final scheme = Theme.of(context).colorScheme;
    final name = widget.app.workspace.settings['name']?.trim() ?? '';
    final unread = widget.app.workspace.inbox
        .where((item) => !item.processed)
        .length;
    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 24),
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
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => showSearchPalette(context, widget.app),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: .7),
                    ),
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
                        Text(
                          'Ctrl K',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
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
        ],
      ),
    );
  }

  Widget _nav(int index, String label, IconData icon, bool compact) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    child: Semantics(
      button: true,
      selected: selected == index,
      label: '$label navigation',
      child: Tooltip(
        message: label,
        child: Material(
          color: selected == index
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => go(index),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 17 : 13,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
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
  );
}
