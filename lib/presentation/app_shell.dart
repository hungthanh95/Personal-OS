import 'dart:async';
import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import 'screens/today_screen.dart';
import 'screens/direction_screens.dart';
import 'screens/library_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/strategy_screens.dart';

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

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final pages = [
      TodayScreen(app),
      MissionScreen(app),
      StrategyScreen(app),
      ProjectsScreen(app),
      LibraryScreen(app),
      AdaptiveReviewScreen(app),
      InboxScreen(app),
      SettingsScreen(app, widget.databasePath, onRestore: widget.onRestore),
    ];
    return CallbackShortcuts(
      bindings: const {},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                return Row(
                  children: [
                    Container(
                      width: compact ? 76 : 232,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: .5),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 22 : 24,
                              32,
                              16,
                              8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.blur_on,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                                if (!compact) ...[
                                  const SizedBox(width: 10),
                                  const Flexible(
                                    child: Text(
                                      'PERSONAL OS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: .7,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!compact)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                              child: Text(
                                app.workspace.settings['demo'] == 'true'
                                    ? 'DEMO WORKSPACE · LOCAL'
                                    : 'YOUR WORKSPACE · LOCAL',
                                style: const TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView(
                              children: [
                                for (var i = 0; i < 6; i++)
                                  _nav(
                                    i,
                                    const [
                                      'Today',
                                      'Mission',
                                      'Strategy',
                                      'Projects',
                                      'Knowledge',
                                      'Review',
                                    ][i],
                                    const [
                                      Icons.grid_view_rounded,
                                      Icons.flag_outlined,
                                      Icons.account_tree_outlined,
                                      Icons.folder_outlined,
                                      Icons.auto_stories_outlined,
                                      Icons.view_week_outlined,
                                    ][i],
                                    compact,
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          _utility(
                            'Search',
                            Icons.search,
                            compact,
                            () => showSearchPalette(context, app),
                          ),
                          _nav(6, 'Inbox', Icons.inbox_outlined, compact),
                          _nav(7, 'Settings', Icons.tune, compact),
                          if (!compact)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Intention → Evidence',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
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
                            child: IndexedStack(
                              index: selected,
                              children: pages,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
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
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => selected = index),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 17 : 14,
                vertical: 14,
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
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: selected == index
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (index == 6 &&
                        widget.app.workspace.inbox.any(
                          (i) => !i.processed,
                        )) ...[
                      const Spacer(),
                      Text(
                        '${widget.app.workspace.inbox.where((i) => !i.processed).length}',
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
  Widget _utility(
    String label,
    IconData icon,
    bool compact,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Tooltip(
      message: '$label · Ctrl/Cmd+K',
      child: TextButton(
        onPressed: action,
        child: Row(
          mainAxisAlignment: compact
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            if (!compact) ...[
              const SizedBox(width: 14),
              Text(label),
              const Spacer(),
              const Text('⌘ K', style: TextStyle(fontSize: 11)),
            ],
          ],
        ),
      ),
    ),
  );
}
