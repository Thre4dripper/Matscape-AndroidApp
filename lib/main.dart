import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app_state.dart';
import 'app/google_account.dart';
import 'app/storage.dart';
import 'app/sync.dart';
import 'ui/scope.dart';
import 'ui/theme.dart';
import 'ui/workspace_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(FileStorage());
  await state.load();
  final sync = SyncController(
    state: state,
    account: GoogleDriveAccount(),
    local: FileStorage.local('sync.json'),
  );
  runApp(MatscapeApp(state: state, sync: sync));
  // After the first frame: the app never waits for the network to open.
  unawaited(sync.start());
}

class MatscapeApp extends StatefulWidget {
  const MatscapeApp({super.key, required this.state, this.sync});
  final AppState state;

  /// Google Drive sync; absent in tests that don't need it.
  final SyncController? sync;

  @override
  State<MatscapeApp> createState() => _MatscapeAppState();
}

class _MatscapeAppState extends State<MatscapeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't lose the last edits if the app is closed from the background.
    if (state != AppLifecycleState.resumed) widget.state.flush();
    // Back in front: pick up what changed on other devices.
    if (state == AppLifecycleState.resumed) widget.sync?.resumed();
    if (state == AppLifecycleState.paused) widget.sync?.paused();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope(
      state: widget.state,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final mode = switch (widget.state.settings.theme) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          return MaterialApp(
            title: 'Matscape',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: buildTheme(Palette.light),
            darkTheme: buildTheme(Palette.night),
            builder: (context, child) {
              // Status and navigation bar icons follow the app theme.
              final dark = context.pal.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value:
                    (dark
                            ? SystemUiOverlayStyle.light
                            : SystemUiOverlayStyle.dark)
                        .copyWith(
                          statusBarColor: const Color(0x00000000),
                          systemNavigationBarColor: const Color(0x00000000),
                          systemNavigationBarIconBrightness: dark
                              ? Brightness.light
                              : Brightness.dark,
                        ),
                // Very large system font sizes would break the keypad grid.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: child!,
                ),
              );
            },
            home: const WorkspaceScreen(),
          );
        },
      ),
    );
    final sync = widget.sync;
    return sync == null ? app : SyncScope(sync: sync, child: app);
  }
}
