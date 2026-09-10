import 'package:copist/src/core/language.dart';
import 'package:copist/src/ui/close_guard.dart';
import 'package:copist/src/ui/shell.dart';
import 'package:copist/src/ui/unsaved_notes.dart';
import 'package:copist/src/ui/window_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget of the Copist application.
///
/// Owns the [MaterialApp], the system-brightness Material theme, and the
/// app language: it keeps [AppLanguages.system] in step with the OS and
/// rebuilds everything below when the resolved language changes, so a
/// language switch reaches every open screen at once.
class CopistApp extends StatefulWidget {
  /// Creates the application root.
  const new({super.key});

  @override
  State<CopistApp> createState() => _CopistAppState();
}

class _CopistAppState extends State<CopistApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readSystemLanguage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The OS language changed while the app was running.
  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    _readSystemLanguage();
  }

  void _readSystemLanguage() {
    AppLanguages.system = AppLanguages.fromLocales(
      WidgetsBinding.instance.platformDispatcher.locales,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppLanguages.revision,
      builder: (context, _, _) => MaterialApp(
        title: 'Copist',
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        locale: AppLanguages.locale,
        supportedLocales: [
          for (final language in AppLanguages.supported) Locale(language.id),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // The close guard sits directly under the MaterialApp, not above
        // it: the ask is a dialog, so it needs the Navigator and the
        // ScaffoldMessenger the app provides.
        home: Consumer(
          builder: (context, ref, _) => CloseGuard(
            tracker: ref.watch(unsavedTrackerProvider),
            window: ref.watch(windowControllerProvider),
            child: const LibraryHome(),
          ),
        ),
      ),
    );
  }
}

/// Builds the system-brightness Material theme used until the full
/// brightness x palette token system lands in M6.
///
/// The seed color doubles as the placeholder branding accent and is
/// expected to be replaced by the M6 token system.
ThemeData buildAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF45475A),
    brightness: brightness,
  );
  return ThemeData(brightness: brightness, colorScheme: colorScheme);
}
