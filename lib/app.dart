import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../apps_list/apps_list.dart';
import '../logs/log_page.dart';
import '../theme/theme.dart';
import 'hotkey/hotkey.dart';
import 'loading/loading_page.dart';
import 'localization/app_localizations.dart';
import 'settings/settings.dart';
import 'window/app_window.dart';

/// The root widget of the app.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TrayListener, WindowListener {
  /// Maximum interval between two left clicks on the tray icon for them
  /// to be considered a double click.
  static const Duration _doubleClickThreshold = Duration(milliseconds: 400);

  /// Time of the most recent left click on the tray icon.
  DateTime? _lastTrayIconMouseDown;

  /// Pops up the tray context menu after a single left click.
  ///
  /// The short delay allows a possible second click to be recognized as a
  /// double click instead of leaving a context menu open.
  Timer? _traySingleClickTimer;

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    _traySingleClickTimer?.cancel();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    final appWindow = context.read<AppWindow>();

    if (settingsCubit.state.closeToTray) {
      appWindow.hide();
    } else {
      appWindow.close();
    }
  }

  Timer? timer;

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'move' || eventName == 'resize') {
      /// Set a timer between events that trigger saving the window size and
      /// location. This is required because there is no notification available
      /// for when these events *finish*, and therefore it would be triggered
      /// hundreds of times otherwise during a move event.
      timer?.cancel();
      timer = null;
      timer = Timer(
        const Duration(seconds: 5),
        () {
          context.read<AppWindow>().saveWindowSizeAndPosition();
        },
      );
    }
    super.onWindowEvent(eventName);
  }

  @override
  void onWindowRestore() {
    context.read<AppsListCubit>().manualRefresh();
    super.onWindowRestore();
  }

  @override
  void onTrayIconMouseDown() {
    // Fired on left click. Wait briefly for a possible second click: if one
    // arrives, treat it as a double click and show the main window, otherwise
    // pop up the context menu as before.
    // https://github.com/Merrit/nyrna/issues/271
    final DateTime now = DateTime.now();
    final bool isDoubleClick =
        (_lastTrayIconMouseDown != null) &&
        now.difference(_lastTrayIconMouseDown!) <= _doubleClickThreshold;

    if (isDoubleClick) {
      _traySingleClickTimer?.cancel();
      _traySingleClickTimer = null;
      _lastTrayIconMouseDown = null;
      context.read<AppWindow>().show();
    } else {
      _lastTrayIconMouseDown = now;
      _traySingleClickTimer?.cancel();
      _traySingleClickTimer = Timer(_doubleClickThreshold, () {
        trayManager.popUpContextMenu();
      });
    }
    super.onTrayIconMouseDown();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
    super.onTrayIconRightMouseDown();
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcuts(
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Nyrna',
            debugShowCheckedModeBanner: false,
            theme: state.themeData,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              LoadingPage.id: (context) => const LoadingPage(),
              LogPage.id: (context) => LogPage(),
              AppsListPage.id: (context) => const AppsListPage(),
              SettingsPage.id: (conext) => SettingsPage(),
            },
            home: const LoadingPage(),
          );
        },
      ),
    );
  }
}
