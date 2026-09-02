import 'package:copist/src/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrypoint of the Copist application.
void main() {
  runApp(const ProviderScope(child: CopistApp()));
}
