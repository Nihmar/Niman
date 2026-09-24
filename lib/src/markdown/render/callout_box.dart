/// A callout in the read view (#279): a box of its type's colour, a bar
/// down its left, its icon and title on top, and what it says under them —
/// folded away while a callout that folds is closed.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/render/callout_style.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

/// A callout's box, open or closed.
final class CalloutBox extends StatefulWidget {
  /// A box for [callout], drawn with [theme], around [body].
  const new({
    required this.callout,
    required this.theme,
    required this.body,
    super.key,
  });

  /// What the callout line says.
  final Callout callout;

  /// The note's theme: the bar's width, the indent, the title's size.
  final MarkdownTheme theme;

  /// What the callout says, drawn as the quote's content is.
  final List<Widget> body;

  @override
  State<CalloutBox> createState() => _CalloutBoxState();
}

final class _CalloutBoxState extends State<CalloutBox> {
  /// Whether the body shows: a closed callout starts folded, as its `-`
  /// says; the reader opens it, and the note is not written to.
  late bool _open = widget.callout.fold != CalloutFold.closed;

  @override
  void didUpdateWidget(CalloutBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.callout.fold != widget.callout.fold) {
      _open = widget.callout.fold != CalloutFold.closed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final callout = widget.callout;
    final theme = widget.theme;
    final style = calloutStyleOf(callout.type);
    final folds = callout.fold != CalloutFold.none;
    final titleStyle = theme.body.copyWith(
      color: style.color,
      fontWeight: FontWeight.w600,
    );
    // The note's text size as it is drawn, as `live` sizes the icon.
    final em = MediaQuery.textScalerOf(context)
        .scale(theme.body.fontSize ?? 14);
    final size = em * 1.2;
    Widget title = Row(
      children: <Widget>[
        Icon(style.icon, size: size, color: style.color),
        SizedBox(width: size * 0.4),
        Flexible(child: Text(callout.title, style: titleStyle)),
        if (folds) ...<Widget>[
          SizedBox(width: size * 0.2),
          Icon(
            _open ? Icons.expand_more : Icons.chevron_right,
            size: size,
            color: style.color,
          ),
        ],
      ],
    );
    if (folds) {
      title = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: const Key('callout-fold'),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: title,
        ),
      );
    }
    // The quote's indent and nothing else: the title is one of `live`'s
    // rows and the body its rows, so the page does not move when it flips.
    return Container(
      decoration: BoxDecoration(
        color: calloutBackground(style.color),
        border: Border(
          left: BorderSide(color: style.color, width: theme.quoteBarWidth),
        ),
      ),
      padding: EdgeInsets.only(
        left: theme.quoteIndentPerLevel - theme.quoteBarWidth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(header: true, expanded: folds ? _open : null, child: title),
          if (_open) ...widget.body,
        ],
      ),
    );
  }
}
