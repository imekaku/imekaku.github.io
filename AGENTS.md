# AGENTS.md

Jekyll personal blog served by GitHub Pages at `blog.imekaku.com` (CNAME). No Gemfile, no plugins, no build toolchain beyond Jekyll itself. The vendored TOC include is the only non-standard piece.

## Commands

- `jekyll serve` — local dev at http://localhost:4000
- `jekyll build` / `jekyll clean`
- No tests, lint, or typecheck — this is a content repo. Verify changes by serving locally.

## Content types & frontmatter

Three content types, each with a distinct layout and required frontmatter:

| Directory | Layout | Required frontmatter | Notes |
|---|---|---|---|
| `_posts/` | `post` | `title`, `category` | TOC + "Related Posts" (Related Posts is just recent posts — no LSI on GitHub Pages; do not try to "fix" it). Filename: `YYYY-MM-DD-title.md` |
| `_life_collection/` | `post_life` | `title`, `category` | TOC, no related posts. Filename: `YYYY-MM-DD-title.md` (book notes may use `YYYY-MM-DD-ISBN.md`) |
| `_thinking_collection/` | `thinking` | `layout` only | No title, no category. Rendered as one chronological list at `/thinking/`. Filename: `YYYY-MM-DD-Weekday.md` (e.g. `2026-05-08-Friday.md`) |

`life_collection` and `thinking_collection` are Jekyll collections declared in `_config.yml`.

## Categories are NOT auto-generated

This is the main gotcha. Adding a new category requires creating a static HTML page, or the category link 404s:

- Blog post category → `category/<name>.html` with `layout: category`, `category: <name>`
- Life collection category → `category_life/<name>.html` with `layout: category_life`, `category: <name>`

The index pages (`category/index.html`, `life/index.html`) auto-list posts; the per-category detail pages are manual.

## MathJax

Conditional per page: `_layouts/default.html` loads MathJax from a CDN only when `formula` is in the page's `tags`. Add `tags: [formula]` (or `tag: [formula]`) to frontmatter to enable math rendering. Jekyll normalizes `tag`/`tags` to the same array.

## TOC

Post layouts include `{% include toc.html html=content h_max=4 %}`. `_includes/toc.html` is a vendored copy of allejo/jekyll-toc v1.2.0 — not a plugin. Do not expect a gem.

## Drafts (`.hide`)

`*.hide` files (e.g. `2026-07-08-july.md.hide`) are gitignored local drafts/WIP. They are not committed and not rendered by Jekyll. To publish, rename to drop `.hide`; to unpublish locally, add `.hide`.

## Assets & build artifacts

- Images are hosted externally on `blogcdn.qihope.com`, not in this repo.
- Stylesheets: `css/screen.css`, `css/syntax.css`.
- `_site/` and `.jekyll-cache/` are build artifacts (gitignored) — never edit by hand.

## Deploy

Pushing to the default branch publishes via GitHub Pages. No CI or build step. Verify locally with `jekyll serve` before pushing.
