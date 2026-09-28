# The documentation site

The guides in `docs/` are published as a GitHub Pages site at
<https://nihmar.github.io/Niman/>. It is the same Markdown you read in the
repository — there is no second copy of the documentation and there is meant
to be none — rendered with Niman's own layouts and stylesheet.

## How it is built

`.github/workflows/pages.yml` builds and deploys the site on every push to
`main`. The build is GitHub Pages' own environment (`actions/jekyll-build-pages`,
the image a branch-based Pages site is built in): no Gemfile, no Node or Python
build, nothing to install or update by hand. Enabling Pages
(*Settings → Pages → Source: GitHub Actions*) is a one-time click a maintainer
makes; until then the workflow has nowhere to deploy to.

Two things are not literal:

- **Liquid renders before Markdown.** Niman's docs carry the app's own template
  syntax — `{{date:FORMAT}}`, `{{ask:Label}}` and the rest of what the templates
  page documents — and Liquid would read those as its tags and drop them. So
  the workflow wraps every line that carries one in a raw block, in the
  checkout only; the pages published are then the Markdown in the repository,
  character for character. `index.md` is the site's own page and uses Liquid on
  purpose, and `README.md` is never rendered by this build, so neither is
  wrapped.
- **GitHub's plugins are on**, not Jekyll's bare defaults: pages under `docs/`
  have no front matter (`jekyll-optional-front-matter` supplies one), each
  page's title is taken from its first heading
  (`jekyll-titles-from-headings`), `docs/README.md` and `docs/records/README.md`
  become their folders' indexes (`jekyll-readme-index`), and relative links to
  `*.md` are rewritten to the pages they point at (`jekyll-relative-links`).

## Preview it locally

The reference environment is the `github-pages` gem. Install Ruby and Bundler,
then — because the repository ships no Gemfile by design — make a throwaway one
somewhere you will not commit, and serve the site from the repository root:

```
# Gemfile — temporary; do not commit
source 'https://rubygems.org'
gem 'github-pages', group: :jekyll_plugins

bundle install
bundle exec jekyll serve --baseurl /Niman
```

Then open <http://127.0.0.1:4000/Niman/>. `--baseurl /Niman` matches `baseurl`
in `_config.yml`, which is what every internal URL is built from; a project
site is served from a subpath, so a preview without it will 404 on the
stylesheet and the links. To see the placeholder-heavy pages (the templates
page, the design records) exactly as they publish, run the workflow's raw step
over the checkout first and undo it afterwards with a `git checkout` of the
`docs/` tree — locally, Liquid would otherwise eat Niman's own template syntax.

A branch build cannot be deployed: Pages deploys from `main`. A pull request
changes the site as soon as it is merged; before that, look at the HTML the
build above writes to `_site/`, or at the deploy preview after the merge.

## Where the site lives

| Path | What it is |
|------|------------|
| `_config.yml` | the title, the description, `baseurl` (must name `/Niman`), the `page` default layout, and the source tree the build leaves out |
| `index.md` | the landing page: `layout: home`, plus its guide lists |
| `_layouts/default.html` | the shell every page wears: the head, the header, the main, the footer, and the theme toggle |
| `_layouts/home.html` | the landing: the hero, the pill buttons, the screenshot gallery and the feature cards |
| `_layouts/page.html` | a documentation page: the sidebar, the breadcrumb, the prose and the "edit this page" link |
| `_includes/nav.html` | the header: the mark, the nav and the theme toggle's button |
| `_includes/sidebar.html`, `_includes/sidebar_item.html` | the docs sidebar, built from `site.pages` |
| `_includes/footer.html` | the footer and the ways out |
| `assets/css/site.css` | the one stylesheet, and the palette it defines |

The sidebar is generated from `site.pages`: every page under `docs/user/`,
`docs/dev/` and `docs/records/` appears in it, marked when it is the page being
read. A new guide shows up on its own; the order it appears in is the order it
is written in — the lists in `index.md` and the table in
`docs/records/README.md` — held as one line per group near the top of
`_includes/sidebar.html`, so keep those in step.

`assets/css/site.css` is hand-written and self-contained: no framework, no CDN,
no web font. Its colours are the app's own — the anthracite, cream and blue of
the logo, taken from `lib/src/core/theme_tokens.dart` as the Niman theme fills
them in (`lib/src/ui/theme/niman.dart`). Light and dark follow
`prefers-color-scheme`, and the header's toggle writes an explicit choice to
`localStorage` (a few lines of inline script, no library). The app's Literata
face is in the repository (`assets/fonts/literata/`) if the site ever wants it;
the stylesheet uses the system stack so a page stays light.

The mark is `logos/svg/niman-mark.svg`, the same file the landing and the
favicon use.
