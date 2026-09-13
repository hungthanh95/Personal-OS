import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/main.dart';
import 'package:personal_os/application/app_controller.dart';
import 'package:personal_os/infrastructure/sqlite_repository.dart';

void main() {
  late SqliteWorkspaceRepository repo;
  late AppController app;
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('personal_os_widgets_');
    repo = await SqliteWorkspaceRepository.open('${temp.path}/test.sqlite');
    app = AppController(repo);
    await app.refresh();
  });
  tearDown(() async {
    app.dispose();
    await repo.close();
    await temp.delete(recursive: true);
  });

  Future<void> mutate(WidgetTester tester, Finder button) async {
    final completed = Completer<void>();
    void changed() {
      if (!completed.isCompleted) completed.complete();
    }

    app.addListener(changed);
    try {
      await tester.tap(button);
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

  testWidgets('Desktop shell renders demo, all destinations and both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PersonalOsApp(app: app));
    await tester.pumpAndSettle();
    expect(find.text('PERSONAL OS'), findsOneWidget);
    expect(find.text('Modern C++ — Smart Pointers'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final label in [
      'Mission',
      'Strategy',
      'Projects',
      'Knowledge',
      'Review',
      'Inbox',
      'Settings',
      'Today',
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.runAsync(
      () => app.save('settings', {'key': 'theme', 'value': 'dark'}),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Session execution records output, learning and next action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PersonalOsApp(app: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session').first);
    await tester.pumpAndSettle();
    await mutate(tester, find.text('Start session').last);
    await tester.pumpAndSettle();
    expect(find.text('Finish & record result'), findsOneWidget);
    await tester.tap(find.text('Finish & record result'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Actual output · evidence of useful work'),
      'A working unique_ptr example',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'What did I learn?'),
      'Ownership is explicit',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Next action'),
      'Compare shared_ptr',
    );
    await mutate(tester, find.text('Save review'));
    await tester.pumpAndSettle();
    expect(
      app.workspace.outputs.any(
        (o) => o.text('description') == 'A working unique_ptr example',
      ),
      isTrue,
    );
    expect(
      app.workspace.knowledge.any(
        (k) => k.text('content') == 'Ownership is explicit',
      ),
      isTrue,
    );
    expect(app.workspace.project('cpp-path')!.nextAction, 'Compare shared_ptr');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Quick capture form saves and Ctrl+K finds linked records', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PersonalOsApp(app: app));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Create capture'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Try serial trace analysis',
    );
    await mutate(tester, find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      app.workspace.inbox.any((i) => i.title == 'Try serial trace analysis'),
      isTrue,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Smart Pointers');
    await tester.pumpAndSettle();
    expect(find.text('Session'), findsOneWidget);
    await tester.tap(find.text('Session'));
    await tester.pumpAndSettle();
    expect(find.text('Focus session'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Create capture'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
