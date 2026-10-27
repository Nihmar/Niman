import 'package:flutter/material.dart';
import 'package:niman/src/ui/tree_rename_field.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';

/// A row being made in the tree (#712): a note or a folder in `folder`
/// ('' the root), its name typed where it will be, `initial` proposed;
/// `submit` and `cancel` as a rename's.
typedef TreeCreate = ({
  String folder,
  bool isDir,
  String initial,
  Future<String?> Function(String name) submit,
  VoidCallback cancel,
});

/// The row of a note or a folder being made (#712): its icon, and its
/// name in a field, at the [depth] it will sit.
final class TreeCreateRow extends StatelessWidget {
  /// The row of [creating], drawn [depth] levels in.
  const new({required this.creating, required this.depth, super.key});

  /// What is being made, and what its field does.
  final TreeCreate creating;

  /// How many levels in the row sits.
  final int depth;

  @override
  Widget build(BuildContext context) {
    final metrics = TreeRowMetrics.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const Key('tree-create-row'),
      constraints: BoxConstraints(minHeight: metrics.height),
      padding: EdgeInsets.only(left: depth * metrics.indent + 8),
      child: Row(
        children: [
          SizedBox(
            width: metrics.leading,
            child: Icon(
              creating.isDir
                  ? Icons.create_new_folder_outlined
                  : Icons.note_add_outlined,
              size: 16,
            ),
          ),
          Expanded(
            child: TreeRenameField(
              name: creating.initial,
              isDir: creating.isDir,
              keepsUnchanged: true,
              floatingError: true,
              style: theme.textTheme.bodyMedium,
              onSubmit: creating.submit,
              onCancel: creating.cancel,
            ),
          ),
        ],
      ),
    );
  }
}
