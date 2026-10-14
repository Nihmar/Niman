/// Where an export's progress shows (#712): a dialog that holds the window
/// on a phone, and on a desktop a card in the window's corner that holds
/// nothing — the note stays to be written in while a long PDF is drawn.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_density.dart';

/// Shows the progress [build] draws until [done] completes. [build] is
/// told whether it is a modal dialog, which closes itself, or a card,
/// which this takes down.
void showExportProgress(
  BuildContext context, {
  required Future<void> done,
  required Widget Function(BuildContext context, {required bool modal}) build,
}) {
  if (!pointerDense(Theme.of(context))) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => build(context, modal: true),
      ),
    );
    return;
  }
  final overlay = Overlay.of(context, rootOverlay: true);
  final card = OverlayEntry(
    builder: (context) => Positioned(
      right: 16,
      bottom: 16,
      child: ConstrainedBox(
        key: const Key('export-progress-card'),
        constraints: const BoxConstraints(maxWidth: 420),
        // The dialog's own margins are for the middle of a window.
        child: MediaQuery.removeViewInsets(
          context: context,
          child: Theme(
            data: Theme.of(context).copyWith(
              dialogTheme: Theme.of(context).dialogTheme
                  .copyWith(insetPadding: EdgeInsets.zero),
            ),
            child: build(context, modal: false),
          ),
        ),
      ),
    ),
  );
  overlay.insert(card);
  void remove(Object? _) {
    if (card.mounted) card.remove();
    card.dispose();
  }

  unawaited(done.then(remove, onError: remove));
}
