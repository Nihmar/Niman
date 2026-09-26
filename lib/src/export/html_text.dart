/// Escaping for the exported page (#24): what text and attribute values
/// must not carry into HTML as markup.
library;

/// [text] safe as an element's content.
String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// [text] safe inside a double-quoted attribute value.
String escapeAttribute(String text) =>
    escapeHtml(text).replaceAll('"', '&quot;');
