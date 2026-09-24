/// The Markdown cheatsheet (#265): every construct, written and shown.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/cheatsheet/cheatsheet_entries.dart';
import 'package:niman/src/ui/cheatsheet/cheatsheet_example.dart';
import 'package:niman/src/ui/strings.dart';

/// Opens the cheatsheet over the app. [onInsert] puts an example in the
/// open note — the page closes first, so the note is what the writer sees
/// it land in — and is null when no note is open to take one.
Future<void> showMarkdownCheatsheet(
  BuildContext context, {
  ValueChanged<String>? onInsert,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (context) => CheatsheetScreen(
      onInsert: onInsert == null
          ? null
          : (source) {
              Navigator.of(context).pop();
              onInsert(source);
            },
    ),
  ),
);

/// The cheatsheet's page.
final class CheatsheetScreen extends StatefulWidget {
  /// Creates the page.
  const new({this.onInsert, super.key});

  /// Puts an example in the open note; null when none is open.
  final ValueChanged<String>? onInsert;

  @override
  State<CheatsheetScreen> createState() => _CheatsheetScreenState();
}

final class _CheatsheetScreenState extends State<CheatsheetScreen> {
  /// The page's formulas, typeset once for all its examples.
  final MathCache _math = MathCache();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.cheatsheetTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // A page to read, not a row of the window's full width.
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView.separated(
              key: const Key('cheatsheet'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: cheatsheetEntries.length,
              separatorBuilder: (context, _) => const Divider(),
              itemBuilder: (context, index) => CheatsheetExample(
                entry: cheatsheetEntries[index],
                mathCache: _math,
                onInsert: widget.onInsert,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
