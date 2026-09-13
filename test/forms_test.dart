import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/main.dart';
import 'package:personal_os/application/app_controller.dart';
import 'package:personal_os/infrastructure/sqlite_repository.dart';
import 'package:personal_os/presentation/screens/record_editor.dart';

void main() {
  late SqliteWorkspaceRepository repo;
  late AppController app;
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('personal_os_forms_');
    repo = await SqliteWorkspaceRepository.open('${temp.path}/test.sqlite');
    app = AppController(repo);
    await app.refresh();
  });
  tearDown(() async {
    app.dispose();
    await repo.close();
    await temp.delete(recursive: true);
  });
  Future<void> persist(WidgetTester tester) async {
    final completed = Completer<void>();
    void changed() {
      if (!completed.isCompleted) completed.complete();
    }

    app.addListener(changed);
    try {
      await tester.tap(find.text('Save').last);
      for (var retry = 0; retry < 100 && !completed.isCompleted; retry++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(
        completed.isCompleted,
        isTrue,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' | '),
      );
      await tester.pumpAndSettle();
    } finally {
      app.removeListener(changed);
    }
  }

  testWidgets('All creation forms persist their defaults and relationships', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final table in [
      'goals',
      'projects',
      'sessions',
      'milestones',
      'outputs',
      'knowledge',
      'tasks',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => editRecord(
                  context,
                  app,
                  table,
                  initial: {'project_id': 'cpp-path'},
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'New $table record',
      );
      await persist(tester);
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: '$table should save',
      );
      expect(tester.takeException(), isNull, reason: table);
    }
    expect(
      app.workspace.goals.any((g) => g.title == 'New goals record'),
      isTrue,
    );
    expect(
      app.workspace.sessions.any(
        (s) => s.title == 'New sessions record' && s.projectId == 'cpp-path',
      ),
      isTrue,
    );
    expect(
      app.workspace.milestones.any((m) => m.title == 'New milestones record'),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Narrow desktop and empty workspace have no layout failures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(app.clearDemo);
    await tester.pumpWidget(PersonalOsApp(app: app));
    await tester.pumpAndSettle();
    expect(find.text('Make room for meaningful work'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final label in [
      'Missions',
      'Strategy',
      'Projects',
      'Knowledge',
      'Review',
      'Inbox',
      'Settings',
    ]) {
      await tester.tap(find.byTooltip(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Life Map exposes hierarchy and output library opens Markdown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PersonalOsApp(app: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Missions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage existing goals & project links'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Life Map'));
    await tester.pumpAndSettle();
    expect(
      find.text('Life area → Goal → Project → Milestone / Experiment'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Knowledge').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ownership should be explicit'));
    await tester.pumpAndSettle();
    expect(find.text('Source session: Ownership practice'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
