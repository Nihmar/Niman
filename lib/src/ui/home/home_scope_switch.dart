/// Where the Home being edited is kept (#535): the library's, the same on
/// every device, or this device's own.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/home/home_edit_dialogs.dart';
import 'package:niman/src/ui/home/home_editing.dart';
import 'package:niman/src/ui/strings.dart';

/// *This library* / *Only on this device*.
final class HomeScopeSwitch extends StatelessWidget {
  /// Switches [editing] between the two.
  const new({required this.editing, super.key});

  /// The Home being edited.
  final HomeEditing editing;

  Future<void> _pick(BuildContext context, bool device) async {
    if (device) {
      await editing.keepOnDevice();
      return;
    }
    if (await confirmUseLibraryHome(context)) await editing.useLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      key: const Key('home-scope'),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.cloud_outlined),
          label: Text(AppStrings.navigationScopeLibrary),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.devices_outlined),
          label: Text(AppStrings.navigationScopeDevice),
        ),
      ],
      selected: {editing.onDevice},
      onSelectionChanged: (picked) => unawaited(_pick(context, picked.single)),
    );
  }
}
