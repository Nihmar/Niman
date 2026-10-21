/// What a Mac's app delegate hands the app (docs/records/apple-platforms.md):
/// the notes Finder asks it to open, and the Dock menu's quick actions,
/// over `niman/mac_app` (macos/Runner/AppDelegate.swift).
///
/// A Mac opens a file in the running app rather than starting another, and
/// a double-clicked note starts the app before Dart listens: the delegate
/// keeps those and hands them over when `takePendingFiles` first asks.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// The app delegate's channel.
final class MacAppEvents {
  new _() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'open':
          if (call.arguments case final String path) _files.add(path);
        case 'dockAction':
          if (call.arguments case final String id) _dockActions.add(id);
      }
    });
  }

  /// The one listener, made when first asked for.
  static final MacAppEvents instance = MacAppEvents._();

  static const MethodChannel _channel = MethodChannel('niman/mac_app');

  final StreamController<String> _files = StreamController.broadcast();
  final StreamController<String> _dockActions = StreamController.broadcast();

  /// Notes Finder asks to open while the app runs.
  Stream<String> get files => _files.stream;

  /// The Dock menu's choices, by their quick action's id.
  Stream<String> get dockActions => _dockActions.stream;

  /// The notes asked for before the app listened, once; from then on they
  /// arrive on [files].
  Future<List<String>> takePendingFiles() async {
    try {
      final paths = await _channel.invokeListMethod<String>('takePendingFiles');
      return paths ?? const [];
    } on MissingPluginException {
      return const [];
    }
  }

  /// The Dock menu's entries, in order: each quick action's id and label.
  Future<void> setDockMenu(List<(String, String)> entries) async {
    try {
      await _channel.invokeMethod<void>('setDockMenu', [
        for (final (id, label) in entries) [id, label],
      ]);
    } on MissingPluginException {
      // A Mac runner that does not answer: no Dock menu, nothing lost.
    }
  }
}
