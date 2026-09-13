import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/application/app_controller.dart';
import 'package:personal_os/infrastructure/sqlite_repository.dart';
import 'package:personal_os/main.dart';
import 'package:personal_os/presentation/screens/strategy_screens.dart';

void main() {
  testWidgets(
    'Strategy starter, populated missions and creation forms render at desktop and narrow widths',
    (tester) async {
      late Directory temp;
      late SqliteWorkspaceRepository repo;
      late AppController app;
      await tester.runAsync(() async {
        temp = await Directory.systemTemp.createTemp('strategy_ui_');
        repo = await SqliteWorkspaceRepository.open(
          '${temp.path}/db.sqlite',
          demo: false,
        );
        final raw =
            jsonDecode(
                  await File('assets/strategy_starter.json').readAsString(),
                )
                as Map<String, dynamic>;
        await repo.installStrategyTemplate(
          raw.map(
            (k, v) => MapEntry(
              k,
              (v as List)
                  .map((r) => Map<String, Object?>.from(r as Map))
                  .toList(),
            ),
          ),
        );
        await repo.save('outputs', {
          'id': 'o',
          'title': 'Passing TCP tests',
          'created_at': 1,
        });
        app = AppController(repo);
        await app.refresh();
      });
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: PersonalOsApp(app: app),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Missions').first);
      await tester.pumpAndSettle();
      expect(find.text('Job Switch — Higher Salary'), findsOneWidget);
      expect(find.text('Modern C++'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Details & related workspaces'));
      await tester.tap(find.text('Details & related workspaces'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Career workspace'));
      await tester.tap(find.text('Career workspace'));
      await tester.pumpAndSettle();
      expect(find.text('Skill demand vs readiness'), findsOneWidget);
      expect(find.text('Paste job descriptions'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      for (final table in fields.keys) {
        final ctx = tester.element(find.text('Missions').first);
        final future = editStrategyRecord(ctx, app, table);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: table);
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        await future;
      }
      await tester.tap(find.text('Strategy').first);
      await tester.pumpAndSettle();
      expect(find.text('Higher market value and income'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Projects').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income Lab'));
      await tester.pumpAndSettle();
      expect(find.text('New experiment'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(700, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Missions').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.runAsync(() async {
        await repo.close();
        await temp.delete(recursive: true);
      });
    },
  );
}
