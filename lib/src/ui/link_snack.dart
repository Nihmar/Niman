/// The snackbar a link shows when it went nowhere (split out of
/// `note_links.dart`): one message, shown by the follow path and the
/// dead-link offer alike.
library;

import 'package:flutter/material.dart';

/// Shows [message] in a snackbar; nothing when the context is gone.
void linkSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
