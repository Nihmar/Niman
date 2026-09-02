import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-level state, the single source of truth that later milestones
/// extend.
///
/// In M0 no library has been opened yet, so [libraryPath] is always
/// `null`; M1 populates it when the user opens or creates a library.
@immutable
final class AppState {
  /// Creates the app-level state.
  const AppState({this.libraryPath});

  /// Absolute path of the currently open library root, or `null` when no
  /// library is set.
  final String? libraryPath;
}

/// App-level state provider; wired as the root Riverpod provider scope.
final Provider<AppState> appStateProvider = Provider<AppState>((ref) {
  return const AppState();
});

/// Root widget of the Copist application.
///
/// Owns the [MaterialApp] and the system-brightness Material theme. Runs
/// inside a [ProviderScope] (see `main.dart`), which every later
/// milestone builds on.
class CopistApp extends StatelessWidget {
  /// Creates the application root.
  const CopistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copist',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const _PlaceholderHome(),
    );
  }
}

/// Builds the system-brightness Material theme used until the full
/// brightness × palette token system lands in M6.
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

/// Placeholder home shown until M1 introduces the real library UI.
class _PlaceholderHome extends ConsumerWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Copist')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/branding/feather.png',
              key: const Key('branding'),
              width: 96,
            ),
            const SizedBox(height: 16),
            Text(
              'Copist',
              key: const Key('app-name'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              appState.libraryPath == null
                  ? 'No library set'
                  : appState.libraryPath!,
              key: const Key('library-state'),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
