import 'package:copist/src/ui/shell.dart';
import 'package:flutter/material.dart';

/// Root widget of the Copist application.
///
/// Owns the [MaterialApp] and the system-brightness Material theme.
/// Runs inside the provider scope set up in `main.dart`, which every
/// later milestone builds on.
class CopistApp extends StatelessWidget {
  /// Creates the application root.
  const CopistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copist',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const LibraryHome(),
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
  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
  );
}
