/// What the Apple platforms' app hands Dart (docs/records/apple-platforms.md),
/// over `niman/apple_app`: the notes the system asks it to open — Finder on a
/// Mac (macos/Runner/AppDelegate.swift), the Files app on an iPhone
/// (`packages/niman_apple`'s scene bridge) — and a Mac's Dock menu.
///
/// Both open a file in the running app rather than starting another, and a
/// note opened from outside starts the app before Dart listens: the native
/// side keeps those and hands them over when `takePendingFiles` first asks.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// The app delegate's channel.
final class AppleAppEvents {
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
  static final AppleAppEvents instance = AppleAppEvents._();

  static const MethodChannel _channel = MethodChannel('niman/apple_app');

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
