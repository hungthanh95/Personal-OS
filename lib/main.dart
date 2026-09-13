import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/screens/utilities.dart';
import 'presentation/screens/record_editor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'application/app_controller.dart';
import 'infrastructure/sqlite_repository.dart';
import 'presentation/app_shell.dart';
import 'presentation/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PersonalOsBootstrap());
}

class PersonalOsBootstrap extends StatefulWidget {
  const PersonalOsBootstrap({super.key});
  @override
  State<PersonalOsBootstrap> createState() => _PersonalOsBootstrapState();
}

class _PersonalOsBootstrapState extends State<PersonalOsBootstrap> {
  AppController? app;
  String? failure;
  String path = '';
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    final startup = Stopwatch()..start();
    setState(() => failure = null);
    try {
      const override = String.fromEnvironment('PERSONAL_OS_DB');
      path = override.isNotEmpty
          ? override
          : p.join(
              (await getApplicationSupportDirectory()).path,
              'personal_os.sqlite',
            );
      final repository = await SqliteWorkspaceRepository.open(path);
      final controller = AppController(repository);
      try {
        await controller.refresh();
        startup.stop();
        await repository.save('settings', {
          'key': 'last_startup_ms',
          'value': '${startup.elapsedMilliseconds}',
        });
        await controller.refresh();
      } catch (_) {
        await repository.close();
        rethrow;
      }
      if (mounted) setState(() => app = controller);
    } catch (e) {
      if (mounted) setState(() => failure = '$e');
    }
  }

  Future<void> restoreDatabase(String sourcePath) async {
    if (p.equals(p.absolute(sourcePath), p.absolute(path))) {
      throw ArgumentError('Choose a backup file, not the active database.');
    }
    final source = File(sourcePath);
    if (!await source.exists()) throw ArgumentError('Backup file not found.');
    final header = await source
        .openRead(0, 16)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    if (header.length < 16 ||
        String.fromCharCodes(header) != 'SQLite format 3\u0000') {
      throw const FormatException('The selected file is not a SQLite backup.');
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safetyPath = '$path.before-restore-$stamp.sqlite';
    final stagedPath = '$path.restore-$stamp.tmp';
    await app!.repository.backup(safetyPath);
    try {
      await source.copy(stagedPath);
      final staged = await SqliteWorkspaceRepository.open(
        stagedPath,
        demo: false,
      );
      try {
        await staged.load();
      } finally {
        await staged.close();
      }
    } catch (_) {
      final stagedFile = File(stagedPath);
      if (await stagedFile.exists()) await stagedFile.delete();
      rethrow;
    }
    final previous = app!;
    await previous.repository.close();
    previous.dispose();
    if (mounted) setState(() => app = null);
    try {
      final active = File(path);
      if (await active.exists()) await active.delete();
      await File(stagedPath).rename(path);
      for (final suffix in ['-wal', '-shm']) {
        final sidecar = File('$path$suffix');
        if (await sidecar.exists()) await sidecar.delete();
      }
      await initialize();
    } catch (_) {
      final safety = File(safetyPath);
      if (await safety.exists()) {
        await safety.copy(path);
        await initialize();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    app?.repository.close();
    app?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (app != null) {
      return PersonalOsApp(
        app: app!,
        databasePath: path,
        onRestore: restoreDatabase,
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: personalTheme(Brightness.light),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: failure == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not open your local workspace',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(failure!),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: initialize,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class PersonalOsApp extends StatefulWidget {
  final AppController app;
  final String databasePath;
  final Future<void> Function(String path)? onRestore;
  const PersonalOsApp({
    required this.app,
    this.databasePath = 'test.sqlite',
    this.onRestore,
    super.key,
  });
  @override
  State<PersonalOsApp> createState() => _PersonalOsAppState();
}

class _PersonalOsAppState extends State<PersonalOsApp> {
  final navigator = GlobalKey<NavigatorState>();
  bool utilityOpen = false;
  Future<void> utility(bool search) async {
    if (utilityOpen) return;
    final context = navigator.currentState?.overlay?.context;
    if (context == null) return;
    utilityOpen = true;
    try {
      if (search) {
        await showSearchPalette(context, widget.app);
      } else {
        await editRecord(context, widget.app, 'inbox');
      }
    } finally {
      utilityOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) => MaterialApp(
      navigatorKey: navigator,
      title: 'Personal OS',
      debugShowCheckedModeBanner: false,
      theme: personalTheme(Brightness.light),
      darkTheme: personalTheme(Brightness.dark),
      themeMode: switch (widget.app.workspace.settings['theme']) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      builder: (context, child) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              utility(true),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              utility(true),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              utility(false),
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
              utility(false),
        },
        child: Focus(autofocus: true, child: child!),
      ),
      home: AppShell(
        widget.app,
        widget.databasePath,
        onRestore: widget.onRestore,
      ),
    ),
  );
}
