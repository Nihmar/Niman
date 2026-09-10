import 'dart:async';

import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/text_scale.dart';
import 'package:copist/src/core/theme.dart';
import 'package:copist/src/ui/close_guard.dart';
import 'package:copist/src/ui/shell.dart';
import 'package:copist/src/ui/theme/device_colors.dart';
import 'package:copist/src/ui/theme/palettes.dart';
import 'package:copist/src/ui/unsaved_notes.dart';
import 'package:copist/src/ui/window_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget of the Copist application.
///
/// Owns the [MaterialApp], the theme, the app language and the interface
/// text size: it keeps [AppLanguages.system] in step with the OS and
/// rebuilds everything below when the resolved language, either text
/// scale or the theme changes, so a settings change reaches every open
/// screen at once.
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
    // Material You: what the OS answers arrives a frame or two in, and
    // the app wears its own seed until then (T-M6-05).
    unawaited(readDeviceColors());
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLanguages.revision,
        AppTextScales.revision,
        AppThemes.revision,
      ]),
      builder: (context, _) => MaterialApp(
        title: 'Copist',
        theme: buildAppTheme(AppThemes.palette, Brightness.light),
        darkTheme: buildAppTheme(AppThemes.palette, Brightness.dark),
        themeMode: AppThemes.mode,
        // The interface slider, applied once for the whole app (T-M6-12).
        // It multiplies the platform scaler rather than replacing it, so
        // the OS accessibility setting still counts; the note text does
        // not come through here — re_editor paints its own text and never
        // reads a scaler, and the preview carries the note scale in a
        // MediaQuery of its own.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: ComposedTextScaler(
              MediaQuery.textScalerOf(context),
              AppTextScales.ui,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
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
