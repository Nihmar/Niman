// The two dialogs the Themes page asks with (issue #269): a theme's name,
// and what a new one's colors start from.
//
// One file because the two share the field and the rule behind it: a
// theme is its name to the list, so two themes cannot answer to the same
// one. The field says so while it is typed, rather than after the fact.

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/ui/strings.dart';

/// The themes the New theme dialog offers to start from, each with the
/// label it reads as (the page owns the names; the dialog does not know
/// shipped palettes from the user's own).
typedef ThemeSource = ({AppTheme theme, String label});

/// What the New theme dialog answers: what to call the theme, and the
/// theme to copy its colors from — null for colors invented on the spot.
typedef NewThemeRequest = ({String name, AppTheme? from});

/// Asks for a theme's name, refusing one the list already has; null when
/// the dialog is dismissed.
///
/// [takenNames] holds the names already in use, lowercased — the name
/// being renamed away from is the caller's to leave out.
Future<String?> showThemeNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
  required Set<String> takenNames,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ThemeNameDialog(
      title: title,
      initial: initial,
      takenNames: takenNames,
    ),
  );
}

/// Asks for a new theme's name and where its colors start from; null when
/// the dialog is dismissed.
Future<NewThemeRequest?> showNewThemeDialog(
  BuildContext context, {
  required List<ThemeSource> sources,
  required Set<String> takenNames,
}) {
  return showDialog<NewThemeRequest>(
    context: context,
    builder: (context) =>
        _NewThemeDialog(sources: sources, takenNames: takenNames),
  );
}

/// The name field both dialogs ask with: the current text, its error, and
/// the rule that a name is free.
final class _ThemeNameField extends StatelessWidget {
  const new({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      // The limit is what a name may be, not something to explain: the
      // counter that would say it is a second line the dialog does not
      // need.
      maxLength: CustomTheme.maxNameLength,
      decoration: InputDecoration(
        labelText: AppStrings.themeNewName,
        errorText: error,
        counterText: '',
      ),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

/// The action buttons every dialog here ends with.
List<Widget> _actions({
  required BuildContext context,
  required VoidCallback onConfirm,
  required bool confirmEnabled,
}) => [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text(AppStrings.actionCancel),
  ),
  FilledButton(
    onPressed: confirmEnabled ? onConfirm : null,
    child: Text(AppStrings.actionOk),
  ),
];

final class _ThemeNameDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.initial,
    required this.takenNames,
  });

  final String title;
  final String initial;
  final Set<String> takenNames;

  @override
  State<_ThemeNameDialog> createState() => _ThemeNameDialogState();
}

final class _ThemeNameDialogState extends State<_ThemeNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => CustomTheme.cleanName(_controller.text);

  void _submit() {
    final name = _name;
    if (name.isEmpty) return;
    if (widget.takenNames.contains(name.toLowerCase())) {
      setState(() => _error = AppStrings.themeNameTaken);
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: _ThemeNameField(
        controller: _controller,
        error: _error,
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: _submit,
      ),
      actions: _actions(
        context: context,
        onConfirm: _submit,
        confirmEnabled: _name.isNotEmpty,
      ),
    );
  }
}

final class _NewThemeDialog extends StatefulWidget {
  const new({required this.sources, required this.takenNames});

  final List<ThemeSource> sources;
  final Set<String> takenNames;

  @override
  State<_NewThemeDialog> createState() => _NewThemeDialogState();
}

final class _NewThemeDialogState extends State<_NewThemeDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  /// Where the colors come from; null invents them.
  AppTheme? _from;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => CustomTheme.cleanName(_controller.text);

  void _submit() {
    final name = _name;
    if (name.isEmpty) return;
    if (widget.takenNames.contains(name.toLowerCase())) {
      setState(() => _error = AppStrings.themeNameTaken);
      return;
    }
    Navigator.pop(context, (name: name, from: _from));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(AppStrings.themeNewTitle),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeNameField(
                controller: _controller,
                error: _error,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.themeNewStartFrom,
                style: theme.textTheme.labelLarge,
              ),
              // One group, three kinds of answer: colors invented on the
              // spot, or those of a theme already in the list.
              RadioGroup<AppTheme?>(
                groupValue: _from,
                onChanged: (value) => setState(() => _from = value),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<AppTheme?>(
                      key: const Key('theme-new-random'),
                      value: null,
                      title: Text(AppStrings.themeNewRandom),
                      contentPadding: EdgeInsets.zero,
                    ),
                    for (final source in widget.sources)
                      RadioListTile<AppTheme?>(
                        key: Key('theme-new-from-${source.theme.id}'),
                        value: source.theme,
                        title: Text(source.label),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: _actions(
        context: context,
        onConfirm: _submit,
        confirmEnabled: _name.isNotEmpty,
      ),
    );
  }
}
