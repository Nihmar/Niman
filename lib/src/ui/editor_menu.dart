/// The editor's context menu, grouped by what the writer is doing (#260):
/// the links, then Format, Paragraph and Insert as submenus.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/ui/strings.dart';

/// A Markdown command over the note's text and selection.
typedef MenuCommand = MarkdownEdit Function(String text, TextSelection sel);

/// The menu's structure for a caret whose formats are [active] and whose
/// line is a heading of [headingLevel] (0 for none). [run] applies a
/// command, its `context` lines either side given to it; the image and
/// the footnote go through their own callbacks.
ContextMenuPart editorMenu({
  required Set<ToolbarItem> active,
  required int headingLevel,
  required void Function(MenuCommand command, {int context}) run,
  required VoidCallback onImage,
  required VoidCallback onFootnote,
}) {
  ContextMenuAction wrap(
    String id,
    String label,
    IconData icon,
    String left,
    String right, {
    ToolbarItem? item,
  }) => ContextMenuAction(
    id: 'menu-$id',
    label: label,
    icon: icon,
    active: item != null && active.contains(item),
    onPressed: () => run(
      (text, selection) => wrapSelection(
        text: text,
        selection: selection,
        left: left,
        right: right,
      ),
    ),
  );

  ContextMenuAction command(
    String id,
    String label,
    IconData icon,
    MenuCommand edit, {
    bool on = false,
    int context = 0,
  }) => ContextMenuAction(
    id: 'menu-$id',
    label: label,
    icon: icon,
    active: on,
    onPressed: () => run(edit, context: context),
  );

  const headingIcons = <IconData>[
    Icons.looks_one_outlined,
    Icons.looks_two_outlined,
    Icons.looks_3_outlined,
    Icons.looks_4_outlined,
    Icons.looks_5_outlined,
    Icons.looks_6_outlined,
  ];

  return [
    [
      wrap('link', AppStrings.menuAddLink, Icons.link, '[[', ']]'),
      wrap(
        'external-link',
        AppStrings.menuAddExternalLink,
        Icons.language,
        '[',
        '](https://)',
      ),
    ],
    [
      ContextMenuGroup(
        id: 'menu-format',
        label: AppStrings.menuFormat,
        icon: Icons.text_format,
        sections: [
          [
            wrap(
              'bold',
              AppStrings.toolbarBold,
              Icons.format_bold,
              '**',
              '**',
              item: ToolbarItem.bold,
            ),
            wrap(
              'italic',
              AppStrings.toolbarItalic,
              Icons.format_italic,
              '*',
              '*',
              item: ToolbarItem.italic,
            ),
            wrap(
              'strikethrough',
              AppStrings.toolbarStrikethrough,
              Icons.strikethrough_s,
              '~~',
              '~~',
              item: ToolbarItem.strikethrough,
            ),
            wrap(
              'highlight',
              AppStrings.toolbarHighlight,
              ToolbarItem.highlight.icon,
              '==',
              '==',
              item: ToolbarItem.highlight,
            ),
          ],
          [
            wrap(
              'underline',
              AppStrings.toolbarUnderline,
              Icons.format_underline,
              '<u>',
              '</u>',
              item: ToolbarItem.underline,
            ),
            wrap(
              'superscript',
              AppStrings.toolbarSuperscript,
              Icons.superscript,
              '<sup>',
              '</sup>',
              item: ToolbarItem.superscript,
            ),
            wrap(
              'subscript',
              AppStrings.formatSubscript,
              Icons.subscript,
              '<sub>',
              '</sub>',
            ),
          ],
          [
            wrap(
              'code',
              AppStrings.formatInlineCode,
              Icons.code,
              '`',
              '`',
              item: ToolbarItem.code,
            ),
          ],
        ],
      ),
      ContextMenuGroup(
        id: 'menu-paragraph',
        label: AppStrings.menuParagraph,
        icon: Icons.segment,
        sections: [
          [
            for (var level = 1; level <= 6; level++)
              command(
                'heading-$level',
                '${AppStrings.menuHeadingWord} $level',
                headingIcons[level - 1],
                (text, selection) =>
                    setHeading(text: text, selection: selection, level: level),
                on: headingLevel == level,
              ),
            command(
              'body',
              AppStrings.menuBody,
              Icons.notes,
              (text, selection) =>
                  removeHeading(text: text, selection: selection),
              on: headingLevel == 0,
            ),
          ],
          [
            command(
              'list',
              AppStrings.toolbarList,
              Icons.format_list_bulleted,
              (text, selection) =>
                  prefixLines(text: text, selection: selection, prefix: '- '),
              on: active.contains(ToolbarItem.list),
            ),
            command(
              'ordered-list',
              AppStrings.toolbarOrderedList,
              Icons.format_list_numbered,
              (text, selection) =>
                  orderedList(text: text, selection: selection),
              on: active.contains(ToolbarItem.orderedList),
            ),
            command(
              'checklist',
              AppStrings.toolbarChecklist,
              Icons.checklist,
              (text, selection) =>
                  toggleTaskList(text: text, selection: selection),
              on: active.contains(ToolbarItem.checklist),
            ),
          ],
          [
            command(
              'quote',
              AppStrings.toolbarQuote,
              Icons.format_quote,
              (text, selection) =>
                  prefixLines(text: text, selection: selection, prefix: '> '),
              on: active.contains(ToolbarItem.quote),
            ),
          ],
        ],
      ),
      ContextMenuGroup(
        id: 'menu-insert',
        label: AppStrings.menuInsert,
        icon: Icons.add_box_outlined,
        sections: [
          [
            ContextMenuAction(
              id: 'menu-footnote',
              label: AppStrings.insertFootnote,
              icon: Icons.short_text,
              onPressed: onFootnote,
            ),
            command(
              'table',
              AppStrings.toolbarTable,
              Icons.table_chart_outlined,
              (text, selection) =>
                  insertTable(text: text, selection: selection),
              context: 1,
            ),
            command(
              'rule',
              AppStrings.insertRule,
              Icons.horizontal_rule,
              (text, selection) => insertBlock(
                text: text,
                selection: selection,
                block: const ['---'],
              ),
              context: 1,
            ),
          ],
          [
            command(
              'code-block',
              AppStrings.insertCodeBlock,
              Icons.data_object,
              (text, selection) => codeBlock(text: text, selection: selection),
            ),
            command(
              'math-block',
              AppStrings.insertMathBlock,
              Icons.functions,
              (text, selection) => insertBlock(
                text: text,
                selection: selection,
                block: const [r'$$', '', r'$$'],
                caret: (line: 1, column: 0),
              ),
              context: 1,
            ),
          ],
          [
            ContextMenuAction(
              id: 'menu-image',
              label: AppStrings.toolbarImage,
              icon: Icons.add_photo_alternate_outlined,
              onPressed: onImage,
            ),
          ],
        ],
      ),
    ],
  ];
}
