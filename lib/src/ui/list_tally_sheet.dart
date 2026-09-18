/// The list count's sheet (#136): which list, how to read it, and what
/// it comes out as.
///
/// The preview is the point of the sheet. A count that guessed wrong
/// about where a row's name ends produces a plausible-looking block of
/// nonsense, and the writer finds out after it is in the note; showing
/// the rows it would write turns that into a glance.
///
/// Editor-agnostic on purpose: it takes rows of text and gives back a
/// choice, so the source editor and the WYSIWYG open the same sheet and
/// neither one's idea of a document reaches it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// One list the count could run on.
@immutable
final class TallyCandidate {
  /// Creates a candidate over [rows].
  const new({
    required this.rows,
    this.checks = const <String, bool>{},
    this.replaces = false,
  });

  /// The list's rows, markers and task boxes already stripped.
  final List<String> rows;

  /// The ticks a previous run's block carries, by folded label.
  final Map<String, bool> checks;

  /// Whether a previous run's block is being replaced.
  final bool replaces;

  /// How the picker names this list: its first row.
  String get label => rows.isEmpty ? '' : rows.first;
}

/// What the sheet decided.
@immutable
final class TallyChoice {
  /// Creates a choice.
  const new({required this.index, required this.cut, required this.sort});

  /// Which candidate was counted.
  final int index;

  /// How each row was read.
  final TallyCut cut;

  /// The order the rows came out in.
  final TallySort sort;
}

/// Shows the count's sheet over [candidates], starting on
/// [initialIndex]; resolves to the choice, or null when dismissed.
Future<TallyChoice?> showListTallySheet(
  BuildContext context, {
  required List<TallyCandidate> candidates,
  required int initialIndex,
}) {
  assert(candidates.isNotEmpty, 'the tool is unavailable without a list');
  return showModalBottomSheet<TallyChoice>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ListTallySheet(
      candidates: candidates,
      initialIndex: initialIndex.clamp(0, candidates.length - 1),
    ),
  );
}

final class _ListTallySheet extends StatefulWidget {
  const new({required this.candidates, required this.initialIndex});

  final List<TallyCandidate> candidates;
  final int initialIndex;

  @override
  State<_ListTallySheet> createState() => _ListTallySheetState();
}

final class _ListTallySheetState extends State<_ListTallySheet> {
  late int _index;
  late TallyCut _cut;
  TallySort _sort = TallySort.count;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _cut = detectTallyCut(_candidate.rows);
  }

  TallyCandidate get _candidate => widget.candidates[_index];

  List<TallyRow> get _rows => tallyList(
    rows: _candidate.rows,
    cut: _cut,
    sort: _sort,
    checked: _candidate.checks,
  );

  /// Switching lists re-guesses the cut: the guess belongs to the list
  /// it was made for, and carrying it over would read the new list the
  /// old one's way without saying so.
  void _pick(int index) => setState(() {
    _index = index;
    _cut = detectTallyCut(_candidate.rows);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _rows;
    return SafeArea(
      key: const Key('list-tally-sheet'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionSheetTitle(AppStrings.toolCountListTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _source(theme),
                  const SizedBox(height: 12),
                  _cutField(),
                  const SizedBox(height: 12),
                  _sortField(),
                ],
              ),
            ),
            const Divider(height: 1),
            // The preview scrolls; the buttons under it do not, so the
            // way out of the sheet never goes below the fold.
            Flexible(child: _preview(theme, rows)),
            const Divider(height: 1),
            _buttons(rows),
          ],
        ),
      ),
    );
  }

  /// Which list is being counted: a line when the note has one, a picker
  /// when it has several.
  Widget _source(ThemeData theme) {
    if (widget.candidates.length == 1) {
      return Row(
        children: [
          Text(
            '${AppStrings.tallySourceLabel}  ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              _candidate.label,
              key: const Key('tally-source-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }
    return DropdownButtonFormField<int>(
      key: const Key('tally-source-picker'),
      initialValue: _index,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppStrings.tallySourceLabel,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: <DropdownMenuItem<int>>[
        for (var i = 0; i < widget.candidates.length; i++)
          DropdownMenuItem<int>(
            value: i,
            child: Text(
              widget.candidates[i].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => value == null ? null : _pick(value),
    );
  }

  Widget _cutField() => DropdownButtonFormField<TallyCut>(
    key: const Key('tally-cut-picker'),
    initialValue: _cut,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: AppStrings.tallyCutLabel,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    items: <DropdownMenuItem<TallyCut>>[
      for (final cut in TallyCut.values)
        DropdownMenuItem<TallyCut>(value: cut, child: Text(_cutLabel(cut))),
    ],
    onChanged: (value) => value == null ? null : setState(() => _cut = value),
  );

  Widget _sortField() => DropdownButtonFormField<TallySort>(
    key: const Key('tally-sort-picker'),
    initialValue: _sort,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: AppStrings.tallySortLabel,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    items: <DropdownMenuItem<TallySort>>[
      for (final sort in TallySort.values)
        DropdownMenuItem<TallySort>(value: sort, child: Text(_sortLabel(sort))),
    ],
    onChanged: (value) => value == null ? null : setState(() => _sort = value),
  );

  Widget _preview(ThemeData theme, List<TallyRow> rows) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppStrings.tallyNothingToCount,
          key: const Key('tally-empty'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('tally-preview'),
      shrinkWrap: true,
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // The box a carried-over tick lands in, so the writer can
              // see their ticks survived before they commit to the
              // recount.
              Icon(
                row.checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${row.count}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buttons(List<TallyRow> rows) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          key: const Key('tally-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: const Key('tally-apply'),
          onPressed: rows.isEmpty
              ? null
              : () => Navigator.of(context)
                    .pop(TallyChoice(index: _index, cut: _cut, sort: _sort)),
          child: Text(
            _candidate.replaces
                ? AppStrings.tallyUpdate
                : AppStrings.tallyInsert,
          ),
        ),
      ],
    ),
  );

  static String _cutLabel(TallyCut cut) => switch (cut) {
    TallyCut.dash => AppStrings.tallyCutDash,
    TallyCut.colon => AppStrings.tallyCutColon,
    TallyCut.commas => AppStrings.tallyCutCommas,
    TallyCut.whole => AppStrings.tallyCutWhole,
  };

  static String _sortLabel(TallySort sort) => switch (sort) {
    TallySort.count => AppStrings.tallySortCount,
    TallySort.alphabetical => AppStrings.tallySortAlphabetical,
    TallySort.firstSeen => AppStrings.tallySortFirstSeen,
  };
}
