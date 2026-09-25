/// What the note pane shows for a picture, a PDF or a book it cannot read.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The file could not be shown.
final class AttachmentUnreadable extends StatelessWidget {
  /// The message, centred in the pane.
  const new({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        AppStrings.attachmentUnreadable,
        key: const Key('attachment-unreadable'),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
