/// One run of Readability over a document: its options, the flags it is
/// retried with, the scores it hangs on the nodes, and what it has found so
/// far.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';

/// Readability's options, upstream's defaults.
final class ReadabilityOptions {
  /// The options; each is upstream's own.
  const new({
    this.maxElemsToParse = 0,
    this.nbTopCandidates = 5,
    this.charThreshold = 500,
    this.classesToPreserve = const [],
    this.keepClasses = false,
    this.disableJsonLd = false,
    this.allowedVideoRegex,
    this.linkDensityModifier = 0,
  });

  /// The most elements a document may have; 0 sets no limit.
  final int maxElemsToParse;

  /// How many top candidates are weighed against each other.
  final int nbTopCandidates;

  /// The characters an article needs to be one.
  final int charThreshold;

  /// Classes kept on the article besides Readability's own.
  final List<String> classesToPreserve;

  /// Whether every class is kept.
  final bool keepClasses;

  /// Whether JSON-LD is left unread.
  final bool disableJsonLd;

  /// The embeds kept; upstream's video hosts when null.
  final RegExp? allowedVideoRegex;

  /// Added to the link densities a block may have before it is cleaned.
  final double linkDensityModifier;
}

/// The score Readability hangs on a node (`node.readability`).
final class ContentScore {
  /// A node's score, starting at [contentScore].
  new(this.contentScore);

  /// The score.
  double contentScore;
}

/// The state of one run.
final class ReadabilityRun {
  /// A run over [doc], read from [documentUri].
  new(this.doc, {required this.documentUri, required this.options})
    : classesToPreserve = [
        ...defaultClassesToPreserve,
        ...options.classesToPreserve,
      ];

  /// Strips nodes that are probably not the article.
  static const int flagStripUnlikelys = 0x1;

  /// Weighs classes and ids.
  static const int flagWeightClasses = 0x2;

  /// Cleans blocks that look like anything but the article.
  static const int flagCleanConditionally = 0x4;

  /// The document, changed as the run goes.
  final Document doc;

  /// Where the document was read from.
  final Uri? documentUri;

  /// The run's options.
  final ReadabilityOptions options;

  /// The classes kept on the article.
  final List<String> classesToPreserve;

  /// The flags still on: all of them at first, then fewer at each retry.
  int flags = flagStripUnlikelys | flagWeightClasses | flagCleanConditionally;

  /// The article's title, once the metadata is read.
  String? articleTitle;

  /// The byline found in the page, if the metadata had none.
  String? articleByline;

  /// The article's text direction.
  String? articleDir;

  /// The page's language.
  String? articleLang;

  /// The byline the metadata gave, which stops the page's being looked for.
  String? metadataByline;

  final Expando<ContentScore> _scores = Expando<ContentScore>();
  final Expando<bool> _dataTables = Expando<bool>();

  /// The embeds kept.
  RegExp get allowedVideoRegex =>
      options.allowedVideoRegex ?? ReadabilityPatterns.videos;

  /// Whether [flag] is still on.
  bool flagIsActive(int flag) => flags & flag > 0;

  /// Turns [flag] off.
  void removeFlag(int flag) => flags &= ~flag;

  /// [node]'s score, or null before it is initialized.
  ContentScore? scoreOf(Node node) => _scores[node];

  /// Moves [from]'s score to [to], as a renamed tag keeps it.
  void moveScore(Element from, Element to) {
    final score = _scores[from];
    if (score != null) _scores[to] = score;
  }

  /// Whether [table] was found to hold data, not layout.
  bool isDataTable(Element table) => _dataTables[table] ?? false;

  /// Marks [table] as a data table or a layout one.
  void markDataTable(Element table, {required bool data}) =>
      _dataTables[table] = data;

  /// [node] renamed to [tag], its score kept.
  Element setTag(Element node, String tag) =>
      setNodeTag(node, tag, onMoved: moveScore);

  /// Gives [node] its first score, from its tag and its class weight
  /// (`_initializeNode`).
  ContentScore initializeNode(Element node) {
    final score = _scores[node] = ContentScore(0);
    switch (tagNameOf(node)) {
      case 'DIV':
        score.contentScore += 5;
      case 'PRE' || 'TD' || 'BLOCKQUOTE':
        score.contentScore += 3;
      case 'ADDRESS' || 'OL' || 'UL' || 'DL' || 'DD' || 'DT' || 'LI' || 'FORM':
        score.contentScore -= 3;
      case 'H1' || 'H2' || 'H3' || 'H4' || 'H5' || 'H6' || 'TH':
        score.contentScore -= 5;
    }
    score.contentScore += classWeight(node);
    return score;
  }

  /// What [element]'s class and id say of it: 25 for a good word, -25 for
  /// a bad one, each (`_getClassWeight`).
  int classWeight(Element element) {
    if (!flagIsActive(flagWeightClasses)) return 0;
    var weight = 0;
    for (final value in [classNameOf(element), element.id]) {
      if (value.isEmpty) continue;
      if (ReadabilityPatterns.negative.hasMatch(value)) weight -= 25;
      if (ReadabilityPatterns.positive.hasMatch(value)) weight += 25;
    }
    return weight;
  }
}
