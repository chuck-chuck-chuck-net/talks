# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this is

Published slide decks for talks about the chuck-chuck-chuck.net projects
(slaptain, littlered). One directory per talk, named `<year>-<event>-<project>`.
Each directory is a self-contained [Slidev](https://sli.dev) project with its
own `package.json`, lockfile, fonts and scripts. Never hoist shared tooling to
the root, and never upgrade an old talk's dependencies as a side effect of
working on a new one.

`README.md` lists the talks. When adding one, add its entry there.

This repository is the **published** side. Decks are developed elsewhere and
copied here on release. Treat every file here as public. Everything is licensed
CC BY 4.0 (`LICENSE`).

## Talks

- `2026-ldapcon-slaptain/`: *slaptain: A Kubernetes Operator for Multi-Site
  Multi-Master OpenLDAP*, LDAPCon 2026 (Tübingen, October 6–8). The project itself is
  <https://github.com/chuck-chuck-chuck-net/slaptain>. Its docs and ADRs are the
  source for anything the deck claims. Audience: LDAP practitioners who know
  replication and may know little Kubernetes.

## The one hard rule

After every non-trivial edit to a deck, run `npm run check` in its directory.
It builds the deck into a temp dir and reports only real errors. Mermaid syntax
errors, unknown layouts, missing components and broken frontmatter stay
invisible in `npm run dev` until someone navigates to that slide. Do not verify
a slide edit by reading the file back. Build it.

## Conventions (per talk directory)

- **No HTML comments in a deck.** Slidev compiles `<!-- -->` blocks (speaker
  notes) into the built bundle, so they ship inside every portable HTML while
  being invisible on the rendered slides.
- **Dark mode is forced** (`colorSchema: dark`). The design assumes light text
  on dark `bg-gray-800` boxes.
- **`routerMode: hash` is required** so the portable single-file HTML works
  from `file://`.
- **Fonts are self-hosted** in `fonts/` + `fonts.css` and inlined into the
  portable build. Do not add a Google Fonts CDN link.
- **`vite.config.ts` strips Slidev's `output.manualChunks`.** That is what makes
  `npm run portable` work. Leave it alone.
- **Never use `vh`/`vw` inside a slide.** Slidev scales a fixed 980x551 canvas,
  so viewport units stay pinned to the browser window. Size in `px` against the
  551-unit height instead.
- **Images** go in `public/` and are referenced as `src="/name.svg"`. Most
  diagrams are inline SVG in the deck.
- **Signal colors are chosen for red-green color vision deficiency:** blue
  (`blue-400`) = positive, amber (`amber-400`) = caution, bold orange
  (`text-orange-400 font-bold`) = risk. Never encode a signal in hue alone.
- Artifact filenames come from `name` in the talk's `package.json`.

## The committed PDF

Each talk directory may hold one hand-named, published PDF, un-ignored by an
exact-path line in `.gitignore`. Regenerate it whenever `slides.md` changes.
A plain `npx slidev export` renders only each slide's final click state. Slides
whose clicks *replace* content (`v-click.hide`) lose their earlier states, so
splice those pages in from a `--with-clicks` export with `qpdf`, e.g. for
`2026-ldapcon-slaptain` ("About me" is slide 4; check page numbers with
`pdftotext` first, they drift):

```sh
npx slidev export slides.md --output base.pdf
npx slidev export slides.md --with-clicks --output clicks.pdf
qpdf base.pdf --pages base.pdf 1-3 clicks.pdf 6-7 base.pdf 5-z -- <published>.pdf
```
