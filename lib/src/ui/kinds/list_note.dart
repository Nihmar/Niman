import 'package:copist/src/frontmatter/note_kind.dart';
import 'package:copist/src/ui/kinds/list_parser.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The frontmatter a new list note is created with.
String listNoteContent() => '---\ntype: list\n---\n';

/// The `list` note kind (T-TK-04): a check-list GUI over the note's task
/// items.
final class ListKindGui implements NoteKindGUI {
  @override
  String get type => 'list';

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) {
    return ListNoteView(text: host.text, onChanged: host.applyEdit);
  }
}

/// The list-kind body: the note's task items as checkable rows, nested by
/// indentation, plus an add row.
///
/// Prose in the note is invisible here (the raw editor shows it); every
/// edit is byte-stable ([flipListItem] / [appendListItem]), so nothing
/// else in the note is ever rewritten.
class ListNoteView extends StatefulWidget {
  /// Creates the view; [onChanged] receives the new full note text.
  const ListNoteView({
    required this.text,
    required this.onChanged,
    super.key,
  });

  /// The full note text.
  final String text;

  /// Called with the new full note text after an edit; the host persists
  /// it.
  final ValueChanged<String> onChanged;

  @override
  State<ListNoteView> createState() => _ListNoteViewState();
}

class _ListNoteViewState extends State<ListNoteView> {
  late List<ListItem> _items;
  final TextEditingController _newItem = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = parseListItems(widget.text);
  }

  @override
  void didUpdateWidget(ListNoteView old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _items = parseListItems(widget.text);
    }
  }

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  void _toggle(ListItem item) {
    widget.onChanged(flipListItem(widget.text, item));
  }

  void _add() {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    _newItem.clear();
    widget.onChanged(appendListItem(widget.text, text));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.listEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _itemRow(context, _items[index]),
                ),
        ),
        _addRow(context),
      ],
    );
  }

  Widget _itemRow(BuildContext context, ListItem item) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _toggle(item),
      child: Padding(
        padding: EdgeInsets.only(
          left: 8 + item.depth * 24,
          right: 8,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          children: [
            Checkbox(
              value: item.checked,
              onChanged: (_) => _toggle(item),
            ),
            Expanded(
              child: Text(
                item.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: item.checked
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.checked
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TextField(
        controller: _newItem,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.listAddHint,
          prefixIcon: const Icon(Icons.add),
          suffixIcon: IconButton(
            key: const Key('list-add-button'),
            icon: const Icon(Icons.add),
            tooltip: AppStrings.listAddTooltip,
            onPressed: _add,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (_) => _add(),
      ),
    );
  }
}
