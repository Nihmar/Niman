/// The fences the Insert commands drop at the caret (#530).
///
/// Small on purpose: a writer who asks for a diagram or a mind map gets one
/// node to see the shape, then edits the source.
library;

/// A minimal flowchart: one edge, so the shape is visible at once.
const String mermaidDiagramTemplate =
    '```mermaid\n'
    'flowchart TD\n'
    '  A[Start] --> B[End]\n'
    '```';

/// A minimal mind map: a root and one child.
const String mermaidMindMapTemplate =
    '```mermaid\n'
    'mindmap\n'
    '  root((Mind map))\n'
    '    Idea\n'
    '```';
