// Boards the kanban tests (#1154) read and edit.

/// The board of the design record (docs/records/kanban.md).
const String issueBoard =
    '---\n'
    'type: kanban\n'
    '---\n'
    '## To do\n'
    '- [ ] Write the brief #work\n'
    '- [ ] Book the venue due:2026-11-10\n'
    '\n'
    '## Doing\n'
    '- [ ] Draft the slides\n'
    '  Outline first, then visuals.\n'
    '\n'
    '## Done\n'
    '- [x] Pick the date\n';

/// A board as the Obsidian Kanban plugin writes it: its own frontmatter,
/// blank lines around everything, a tab-indented body, a `**Complete**`
/// line in the last lane and the settings footer.
const String obsidianBoard =
    '---\n'
    '\n'
    'kanban-plugin: board\n'
    '\n'
    '---\n'
    '\n'
    '## To do\n'
    '\n'
    '- [ ] Write the brief #work\n'
    '- [ ] Book the venue due:2026-11-10\n'
    '\n'
    '\n'
    '## Doing\n'
    '\n'
    '- [ ] Draft the slides\n'
    '\tOutline first, then visuals.\n'
    '\n'
    '\n'
    '## Done\n'
    '\n'
    '**Complete**\n'
    '- [x] Pick the date\n'
    '\n'
    '\n'
    '\n'
    '\n'
    '%% kanban:settings\n'
    '```\n'
    '{"kanban-plugin":"board","list-collapse":[false,false,false]}\n'
    '```\n'
    '%%\n';

String crlf(String text) => text.replaceAll('\n', '\r\n');
