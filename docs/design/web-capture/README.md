# Web capture — the screens, and the decisions

The mockups #531 was agreed against (2026-10-07), before any code: six
desktop screens and seven phone screens, in `html/`. They are drawn to look
like Niman, in the Night palette of `lib/src/ui/theme/niman.dart`; where a
mockup and the app disagree, the app is what ships. The plan they belong to
is the record [web-capture.md](../../records/web-capture.md).

| Screen | Desktop | Phone |
|---|---|---|
| Reaching it: **Capture web page…** and **Paste as Markdown** in the command palette; on a phone, New ▸ Capture web page opens the share sheet with a URL field | [Desktop-1-Palette](html/Desktop-1-Palette.html) | [Phone-6-Capture](html/Phone-6-Capture.html) |
| A link shared from the browser: **Page** — folder, tags, "Download 7 images"; Save sends you back to the browser | — | [Phone-1-SharePage](html/Phone-1-SharePage.html) |
| A selection shared from the browser: **Quote** — the quote with the page it came from, Append to note or New note | — | [Phone-2-ShareQuote](html/Phone-2-ShareQuote.html) |
| Reading the page: each step said as it happens ("Downloaded · only 40 words found → Running the page in Edge…"); on a phone, an ongoing notification with Cancel | [Desktop-2-Reading](html/Desktop-2-Reading.html) | [Phone-3-Reading](html/Phone-3-Reading.html) |
| Ready: title, folder, tags, preview (words, images → `assets/`), the frontmatter, what was removed | [Desktop-3-Ready](html/Desktop-3-Ready.html) | — |
| Saved: "Saved: … · Open · Show folder", "Saved without the article", "Quote added" | — | [Phone-4-Saved](html/Phone-4-Saved.html) |
| A link dropped on the window: "Drop to capture this page" | [Desktop-4-Drop](html/Desktop-4-Drop.html) | — |
| **Paste as Markdown**: the clipboard's HTML as Markdown, with the link to its page when the browser gives one, and Undo back to plain text | [Desktop-5-PasteMarkdown](html/Desktop-5-PasteMarkdown.html) | [Phone-7-PasteMarkdown](html/Phone-7-PasteMarkdown.html) |
| The note: source, tags, author, the pictures in the attachments folder | — | [Phone-5-Note](html/Phone-5-Note.html) |
| A page nothing could be read from: title, description, picture, and a quoted notice to open the link | [Desktop-6-Unreadable](html/Desktop-6-Unreadable.html) | — |

## Decided with them

- **No new dependency.** #530 drew its diagrams with an engine of Niman's
  own, so the JS engine #531 was to reuse does not exist. The article is
  found by a Dart port of Mozilla's Readability.js (Apache-2.0) over
  `package:html`, which the EPUB reader already brings; the HTML to Markdown
  conversion is the EPUB reader's, grown for the web.
- **Mozilla's test pages are the oracle**: a subset is kept in the repository
  and the port must give the article upstream gives.
- **The clipboard's HTML is read by Niman's own code** on each platform
  (Windows `HTML Format`, GTK on Linux, `ClipData` on Android), not by a
  plugin.
- **A browser only when the download has too little text**: Edge or a
  Chromium on the desktop, a hidden WebView on Android, each with nothing of
  the user's own browser — no profile, no sign-ins.
- **On a phone the sheet closes at once**: the page is read in the
  background and a notification says when the note is ready.
- **Every platform in the same round**: the capture UI lands on Android,
  Linux and Windows together, and so does Paste as Markdown.
