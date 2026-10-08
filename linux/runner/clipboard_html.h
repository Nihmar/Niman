#ifndef RUNNER_CLIPBOARD_HTML_H_
#define RUNNER_CLIPBOARD_HTML_H_

#include <flutter_linux/flutter_linux.h>

// The clipboard's HTML for Paste as Markdown (#531), over niman/clipboard:
// `readHtml` answers null, or the bytes of the clipboard's text/html and of
// the page the browser says it was copied from.
FlMethodChannel* clipboard_html_channel_new(FlBinaryMessenger* messenger);

#endif  // RUNNER_CLIPBOARD_HTML_H_
