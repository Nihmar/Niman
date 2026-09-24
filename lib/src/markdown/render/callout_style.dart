/// How a callout of each type is drawn (#279): its colour and its icon,
/// Obsidian's, so a note written there reads the same here.
///
/// The colours are the callouts' own, the same in every palette, as a
/// highlighter's is: a warning is orange on any page. The box is the
/// colour at a tenth, and the bar and the title the colour itself.
library;

import 'package:flutter/material.dart';

/// A callout type's colour and icon.
typedef CalloutStyle = ({Color color, IconData icon});

const Color _blue = Color(0xFF086DDD);
const Color _cyan = Color(0xFF00A8A6);
const Color _green = Color(0xFF08B94E);
const Color _orange = Color(0xFFEC7500);
const Color _red = Color(0xFFE93147);
const Color _purple = Color(0xFF7852EE);
const Color _grey = Color(0xFF9E9E9E);

/// The style of a callout of [type]; a type Obsidian does not ship is a
/// note's.
CalloutStyle calloutStyleOf(String type) => switch (type) {
  'abstract' ||
  'summary' ||
  'tldr' => (color: _cyan, icon: Icons.assignment_outlined),
  'info' => (color: _blue, icon: Icons.info_outline),
  'todo' => (color: _blue, icon: Icons.check_circle_outline),
  'tip' ||
  'hint' ||
  'important' => (color: _cyan, icon: Icons.local_fire_department_outlined),
  'success' || 'check' || 'done' => (color: _green, icon: Icons.check),
  'question' || 'help' || 'faq' => (color: _orange, icon: Icons.help_outline),
  'warning' ||
  'caution' ||
  'attention' => (color: _orange, icon: Icons.warning_amber_outlined),
  'failure' || 'fail' || 'missing' => (color: _red, icon: Icons.close),
  'danger' || 'error' => (color: _red, icon: Icons.bolt_outlined),
  'bug' => (color: _red, icon: Icons.bug_report_outlined),
  'example' => (color: _purple, icon: Icons.format_list_bulleted),
  'quote' || 'cite' => (color: _grey, icon: Icons.format_quote_outlined),
  _ => (color: _blue, icon: Icons.edit_outlined),
};

/// The box behind a callout of [color].
Color calloutBackground(Color color) => color.withValues(alpha: 0.1);
