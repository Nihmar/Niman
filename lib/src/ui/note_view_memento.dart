/// The names a note's memento gives the pane it was left in (issue #23):
/// the unified surface in its `source` mode or its `live` one, which the
/// memento calls by the editors' old names so a stored workspace reads the
/// same.
library;

/// The memento's name for the `source` mode.
const String sourceEditorKind = 'source';

/// The memento's name for the `live` mode, once the WYSIWYG editor.
const String wysiwygEditorKind = 'wysiwyg';
