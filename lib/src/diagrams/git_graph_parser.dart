/// The parser behind a `gitGraph` Mermaid fence (#530).
///
/// A git graph is replayed as it is written: `commit`, `branch`,
/// `checkout` (or `switch`), `merge` and `cherry-pick`, each with its
/// `id:`, `tag:`, `type:` and `order:` as Mermaid writes them. Like git
/// itself, it refuses what cannot be done — a branch that does not exist,
/// one made twice, a merge of a branch into itself or of one with nothing
/// new — as a [MermaidParseException] naming the line.
library;

import 'package:niman/src/diagrams/git_graph_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// An argument: `name: "value"` or `name: value`.
final RegExp _argument = RegExp(r'(\w+)\s*:\s*(?:"([^"]*)"|(\S+))');

/// A branch name: a quoted string or the first word.
final RegExp _name = RegExp(r'^\s*(?:"([^"]+)"|(\S+))');

/// Parses a git graph (the fence's content, header included).
GitGraph parseGitGraph(String source) => _GitGraphParser(source).parse();

final class _GitGraphParser {
  new(this.source);

  final String source;
  final List<GitBranch> _branches = [const GitBranch(name: 'main', order: 0)];
  final List<GitCommit> _commits = [];

  /// The last commit on each branch, by branch; null before its first.
  final List<int?> _heads = [null];

  /// The commits written with an id, by id.
  final Map<String, int> _byId = {};
  var _current = 0;

  GitGraph parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim()
        : '';
    final direction = RegExp(
      r'^gitGraph(?:\s+(LR|TB|BT))?\s*:?$',
      caseSensitive: false,
    ).firstMatch(header);
    if (direction == null) {
      throw MermaidParseException(index + 1, 'expected "gitGraph"');
    }
    for (index++; index < lines.length; index++) {
      final line = stripMermaidComment(lines[index]).trim();
      if (line.isNotEmpty) _line(line, index + 1);
    }
    if (_commits.isEmpty) {
      throw const MermaidParseException(1, 'a git graph needs a commit');
    }
    return GitGraph(
      branches: List.unmodifiable(_branches),
      commits: List.unmodifiable(_commits),
      direction: switch (direction.group(1)?.toUpperCase()) {
        'TB' => GitGraphDirection.topDown,
        'BT' => GitGraphDirection.bottomUp,
        _ => GitGraphDirection.leftRight,
      },
    );
  }

  void _line(String line, int number) {
    final space = line.indexOf(RegExp(r'\s'));
    final word = (space < 0 ? line : line.substring(0, space)).toLowerCase();
    final rest = space < 0 ? '' : line.substring(space);
    final arguments = {
      for (final match in _argument.allMatches(rest))
        match.group(1)!.toLowerCase(): match.group(2) ?? match.group(3)!,
    };
    switch (word) {
      case 'commit':
        _commit(arguments, number, parents: _parents());
      case 'branch':
        final name = _branchName(rest, number);
        if (_branches.any((branch) => branch.name == name)) {
          throw MermaidParseException(number, 'branch "$name" already exists');
        }
        final order = double.tryParse(arguments['order'] ?? '');
        _branches.add(
          GitBranch(name: name, order: order ?? _branches.length.toDouble()),
        );
        _heads.add(_heads[_current]);
        _current = _branches.length - 1;
      case 'checkout' || 'switch':
        _current = _branchOf(_branchName(rest, number), number);
      case 'merge':
        final source = _branchOf(_branchName(rest, number), number);
        final theirs = _heads[source];
        if (source == _current) {
          throw MermaidParseException(number, 'a branch cannot merge itself');
        }
        if (theirs == null || theirs == _heads[_current]) {
          throw MermaidParseException(
            number,
            'branch "${_branches[source].name}" has nothing new to merge',
          );
        }
        _commit(
          arguments,
          number,
          parents: [..._parents(), theirs],
          merge: true,
        );
      case 'cherry-pick':
        final id = arguments['id'];
        if (id == null || !_byId.containsKey(id)) {
          throw MermaidParseException(
            number,
            id == null
                ? 'a cherry-pick needs the id: of a commit'
                : 'no commit has the id "$id"',
          );
        }
        _commit(
          {'tag': ?arguments['tag']},
          number,
          parents: _parents(),
          cherryPick: true,
          label: id,
        );
      case 'acctitle:' || 'accdescr:' || 'acctitle' || 'accdescr':
        break;
      default:
        throw MermaidParseException(
          number,
          'expected commit, branch, checkout, merge or cherry-pick, '
          'found "$line"',
        );
    }
  }

  /// The current branch's head, as a new commit's parent.
  List<int> _parents() {
    final head = _heads[_current];
    return head == null ? const [] : [head];
  }

  void _commit(
    Map<String, String> arguments,
    int number, {
    required List<int> parents,
    bool merge = false,
    bool cherryPick = false,
    String? label,
  }) {
    final id = arguments['id'];
    if (id != null && _byId.containsKey(id)) {
      throw MermaidParseException(number, 'the id "$id" is used twice');
    }
    final type = switch (arguments['type']?.toUpperCase()) {
      null || 'NORMAL' => GitCommitType.normal,
      'REVERSE' => GitCommitType.reverse,
      'HIGHLIGHT' => GitCommitType.highlight,
      final other => throw MermaidParseException(
        number,
        'a commit type is NORMAL, REVERSE or HIGHLIGHT, found "$other"',
      ),
    };
    if (id != null) _byId[id] = _commits.length;
    _commits.add(
      GitCommit(
        branch: _current,
        parents: parents,
        label: id ?? label,
        tag: arguments['tag'],
        type: type,
        merge: merge,
        cherryPick: cherryPick,
      ),
    );
    _heads[_current] = _commits.length - 1;
  }

  String _branchName(String rest, int number) {
    final match = _name.firstMatch(rest);
    final name = match?.group(1) ?? match?.group(2);
    if (name == null || name.contains(':')) {
      throw MermaidParseException(number, 'expected a branch name');
    }
    return name;
  }

  int _branchOf(String name, int number) {
    final at = _branches.indexWhere((branch) => branch.name == name);
    if (at < 0) {
      throw MermaidParseException(number, 'no branch is called "$name"');
    }
    return at;
  }
}
