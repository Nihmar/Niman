# Localization — Italian and English

**Status:** Implemented 2026-09-08 (analyze + tests green) — the
on-device check is the user's · **Depends on:** nothing
(`ui/strings.dart` was built for this) · **Spec:** user request: the app
in Italian and English, chosen in the settings, defaulting to the OS
language.

## Purpose

Every user-visible label already lives in one file, `ui/strings.dart`,
precisely so a translation pass would touch only that file. Cash that in:
ship Italian alongside English, follow the OS language by default, and
let the user override it in the settings.

## Current state

156 `static const String` constants in `ui/strings.dart`, referenced 156
times across the app — 23 of them from `const` expressions. `MaterialApp`
declares no `localizationsDelegates`, no `supportedLocales` and no
`locale`, so Flutter's own widgets (date and time pickers, the text
selection menu) are English regardless of the phone's language.

## Agreed decisions

1. **Keep the one-file design; do not adopt ARB/gen_l10n.** The
   alternative — `AppLocalizations.of(context)` — needs a `BuildContext`
   at every call site, which several callers (services, dialogs built
   outside a widget) do not have, and it would rewrite all 156 sites for
   no gain at two languages. Each constant becomes a getter that picks
   between the two texts written side by side:
   `static String get trashTitle => _('Trash', 'Cestino');`
   One line per string, both languages visible together, still one file,
   and the analyzer still catches a typo in a name.
2. **The cost is the `const` sites.** A getter is not a constant, so the
   23 `const Text(AppStrings.x)` sites lose their `const`. That is the
   whole migration cost and it is mechanical.
3. **Language is app-scoped and has three values:** system (default),
   English, Italian. Stored in `app_settings` next to the other
   personal settings.
4. **System means the OS language, resolved once at start** and again
   when the platform locale changes; anything that is not Italian falls
   back to English.
5. **Flutter's own widgets are localized too:** add
   `flutter_localizations`, `supportedLocales: [en, it]`, and drive
   `MaterialApp.locale` from the setting.
6. **Translate, do not transliterate.** The Italian is written for the
   app's own vocabulary (Libreria, nota, cartella, cestino, promemoria) —
   the same vocabulary rule `AGENTS.md` sets for English. Repo files
   (code, comments, plans, commit messages) stay English.

## Tasks

- [x] **T-L10N-01** The mechanism. `AppLanguage` enum (system, english,
  italian), the active language as app state, and the `_(en, it)` helper
  behind it. *AC: unit tests — the helper follows the active language;
  system resolves from the platform locale; an unsupported platform
  locale gives English.*
- [x] **T-L10N-02** Persistence. `language` text column in
  `app_settings` (schema 12 + migration), repo getter/setter on the
  session. *AC: set, reopen, still there.*
- [x] **T-L10N-03** App wiring. `flutter_localizations` +
  `supportedLocales` + `locale` on `MaterialApp`; a language change
  rebuilds the whole app. *AC: widget test — switching the setting
  changes a visible label without restarting; a date picker follows.*
- [x] **T-L10N-04** The settings entry. A three-way choice (System /
  English / Italiano) in the settings list, showing the resolved
  language when it is on System. *AC: widget test — the choice persists
  and the UI follows.*
- [x] **T-L10N-05** The translation. All 156 strings turned into
  `_(en, it)` getters, the 23 `const` call sites fixed. *AC: analyze
  clean; a test asserts every getter returns a non-empty string in both
  languages, so a half-translated constant cannot ship.*
- [x] **T-L10N-06** The strings the file does not own yet. Sweep the
  literals still inline in widgets (dialog titles like `New note`,
  `Move`, `Choose quick note`, the tab titles) into `strings.dart` as
  part of the pass. *AC: a test or a grep gate — no bare user-facing
  literal left in `lib/src/ui/`.*

## Technical design

- **Where the active language lives.** A tiny holder in `core/` (not
  `ui/`) so services can read it, set from the settings at start; the
  root widget listens and rebuilds. `AppStrings` reads the holder, which
  is why call sites do not change.
- **Testing a language.** Tests set the holder directly; no pumping a
  whole app to check a translation.
- **Plurals and dates.** Two cases exist today (`N open` / `N done`,
  short dates in the todo rows). Plurals stay hand-written per language
  in the same getter; dates keep using `intl` with the active locale.

## Exit criteria

- The whole UI is Italian on an Italian phone and English elsewhere,
  with the settings override working both ways.
- Flutter's own dialogs (dates, times, text selection) follow.
- No user-facing English literal left outside `strings.dart`.
- Tests green, analyze clean.

## Risks / open questions

- **Layout under longer Italian text.** Italian labels run longer than
  English; the tight spots are the bottom navigation and the todo filter
  pills. Check both while translating.
- **A third language later.** `_(en, it)` does not scale past a handful
  of languages. If a third is ever wanted, that is the moment to move to
  ARB — recorded here so the decision is not re-litigated by accident.
