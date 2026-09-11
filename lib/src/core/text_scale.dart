// The two text sizes the open library asks for (T-M6-12): one for the
// interface, one for the note.
//
// A small global for the same reason `core/language.dart` is one: the
// values are read from the app root, which sits above every provider, and
// from the editor, which builds its style outside any Material ancestor
// that could carry them. Both are per-library settings, so opening a
// library publishes them here and closing one puts them back to the
// shipped sizes.

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_config.dart';

/// The active text sizes, as multipliers of the sizes the app ships with.
final class AppTextScales {
  const new _();

  /// Bumped whenever either scale changes; the app root listens to it and
  /// rebuilds, so a slider reaches every open screen at once.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static double _ui = defaultTextScale;
  static double _note = defaultTextScale;

  /// The interface multiplier: the tree, the tabs, the todo rows, the
  /// dialogs and the settings themselves.
  static double get ui => _ui;

  static set ui(double value) {
    final scale = normalizeTextScale(value);
    if (_ui == scale) return;
    _ui = scale;
    revision.value++;
  }

  /// The note multiplier: the source editor and the preview of the same
  /// note, which have to agree or switching panes resizes the text.
  static double get note => _note;

  static set note(double value) {
    final scale = normalizeTextScale(value);
    if (_note == scale) return;
    _note = scale;
    revision.value++;
  }

  /// The source editor's font size at the current note scale.
  static double get noteFontSize => baseNoteFontSize * _note;

  /// Publishes both sizes at once, for the open that read them.
  static void apply({required double ui, required double note}) {
    AppTextScales.ui = ui;
    AppTextScales.note = note;
  }

  /// Puts both back to the shipped sizes: no library is open, so no
  /// library's answer applies.
  static void reset() => apply(ui: defaultTextScale, note: defaultTextScale);
}

/// The platform's own text scale at [context], with the interface slider
/// taken back off.
///
/// The app root wraps the platform scaler in a [ComposedTextScaler], so
/// everything below reads at the interface size. A pane that shows note
/// text has to start again from underneath it: composing the note scale
/// onto what it inherits would multiply the two sliders together, and
/// moving the interface one would resize the note.
TextScaler platformTextScalerOf(BuildContext context) {
  final inherited = MediaQuery.textScalerOf(context);
  return inherited is ComposedTextScaler ? inherited.base : inherited;
}

/// The scaler note text is read at: the platform's, times the note
/// slider.
TextScaler noteTextScalerOf(BuildContext context) =>
    ComposedTextScaler(platformTextScalerOf(context), AppTextScales.note);

/// A [TextScaler] that scales on top of another one.
///
/// The interface slider multiplies the platform's text scale rather than
/// replacing it: someone who enlarged text in the OS accessibility
/// settings asked for that everywhere, and a note app is not the place to
/// quietly opt out of it. Composing needs a scaler of its own because
/// [TextScaler] offers no way to combine two — only [TextScaler.clamp],
/// which narrows rather than multiplies.
@immutable
final class ComposedTextScaler implements TextScaler {
  /// Scales by [factor] on top of [base].
  const new(this.base, this.factor);

  /// The scaler this one builds on, normally the platform's.
  final TextScaler base;

  /// The multiplier applied before [base] sees the size.
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize * factor);

  @override
  double get textScaleFactor => base.scale(factor);

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) {
    if (minScaleFactor == 0 && maxScaleFactor == double.infinity) return this;
    return _ClampedComposedTextScaler(this, minScaleFactor, maxScaleFactor);
  }

  @override
  bool operator ==(Object other) =>
      other is ComposedTextScaler &&
      other.base == base &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

/// What [ComposedTextScaler.clamp] returns; the framework's own clamped
/// scaler is private, so the bounds are re-applied here.
@immutable
final class _ClampedComposedTextScaler implements TextScaler {
  const new(this._inner, this._min, this._max);

  final TextScaler _inner;
  final double _min;
  final double _max;

  @override
  double scale(double fontSize) =>
      _inner.scale(fontSize).clamp(fontSize * _min, fontSize * _max);

  @override
  double get textScaleFactor => scale(1);

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) => _ClampedComposedTextScaler(
    _inner,
    minScaleFactor > _min ? minScaleFactor : _min,
    maxScaleFactor < _max ? maxScaleFactor : _max,
  );

  @override
  bool operator ==(Object other) =>
      other is _ClampedComposedTextScaler &&
      other._inner == _inner &&
      other._min == _min &&
      other._max == _max;

  @override
  int get hashCode => Object.hash(_inner, _min, _max);
}
