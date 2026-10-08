# Readability's test pages

The pages the Readability port (`lib/src/capture/readability/`, #531) is
held to, copied from Mozilla's own test suite:

- **Upstream**: <https://github.com/mozilla/readability>, `test/test-pages/`
- **Pinned to**: tag `0.6.0`, commit `04fd32f72b448c12b02ba6c40928b67e510bac49`
- **Licence**: Apache-2.0, [LICENSE.md](LICENSE.md) (upstream's)

Each folder is one page, unchanged: `source.html`, the `expected.html`
article and its `expected-metadata.json`. `test/unit/readability_oracle_test.dart`
reads them as upstream's own test does — the page at
`http://fakehost/test/page.html`, its comments removed, the class `caption`
kept — and compares the article as a tree, not as bytes.

## Which pages

A subset of upstream's 128: every synthetic page, written for one rule
of the algorithm, and the real pages of permissive or institutional sites
— Wikipedia (CC BY-SA), Mozilla and the IETF. The pages of news sites and
blogs stay upstream.

## known-diffs.txt

html5lib (`package:html`) and jsdom do not always build the same tree. A
page where that makes the article differ is listed there with its reason;
the test fails if a listed page matches again, so the list only shrinks.

## Updating

Copy the same folders from a newer upstream tag, update the commit above
and the one named at the head of every file of the port, and run the test.
