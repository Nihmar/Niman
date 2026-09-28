Closes #NNN.

## What

What the change makes true, and the problem it answers.

## Fix

How it does it: the files, the seam it goes in, and the decisions taken.

## Tests

- The test that pins it:
- On the unmodified code, when this fixes a bug — the command and the failure it printed:
- With the fix — the command and its outcome:

## Docs

Which `docs/` page this change updates, in this same PR (`AGENTS.md`).

## Not in this PR

What was left out, and why — the part a reviewer would otherwise look for here.

## Platforms

Which of Android, Linux and Windows the change touches, and what is left behind
where one of them cannot have it.

## Checks

- [ ] `dart fix --apply`, then `dart format lib test tool`
- [ ] `./scripts/niman.sh check` (`flutter analyze --fatal-infos`, then `flutter test`)
- [ ] `./scripts/niman.sh integration`, once the implementation is finished
- [ ] `docs/` updated in this PR
