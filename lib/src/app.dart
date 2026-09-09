import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/text_scale.dart';
import 'package:copist/src/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Root widget of the Copist application.
///
/// Owns the [MaterialApp], the system-brightness Material theme, the app
/// language and the interface text size: it keeps [AppLanguages.system] in
/// step with the OS and rebuilds everything below when the resolved
/// language or either text scale changes, so a settings change reaches
/// every open screen at once.
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLanguages.revision,
        AppTextScales.revision,
      ]),
      builder: (context, _) => MaterialApp(
        title: 'Copist',
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
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
        home: const LibraryHome(),
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
