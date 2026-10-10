# talks

Slide decks for talks about the chuck-chuck-chuck.net projects, currently
[slaptain](https://github.com/chuck-chuck-chuck-net/slaptain) and
[littlered](https://github.com/chuck-chuck-chuck-net/littlered).

Each talk lives in its own directory and is self-contained: its own
`package.json`, lockfile, fonts and build scripts. Talks are not rebuilt when the
toolchain moves on, so a deck from one year keeps building with the versions it
was written against.

The decks are [Slidev](https://sli.dev) markdown. This repository holds the
published source only. Speaker notes and working material are not part of it.

## Talks

### 2026-ldapcon-slaptain

**slaptain: A Kubernetes Operator for Multi-Site Multi-Master OpenLDAP** —
LDAPCon 2026, Tübingen, Germany, October 6–8, 2026.

A design talk about slaptain, a spare-time project: what it takes to run a
multi-site, multi-master OpenLDAP cluster under a Kubernetes operator, how the
operator reconciles replication topology, and how the code got written. Aimed at
LDAP practitioners, not at Kubernetes specialists.

**[Slides as PDF](2026-ldapcon-slaptain/LDAPCON-2026-Dominik-Epple-slaptain-A-Kubernetes-Operator-for-Multi-Site-Multi-Master-OpenLDAP.pdf)** (GitHub shows it inline). It
matches the source here, which is slightly newer than the PDF handed to the
conference: it has an extra appendix section, "Why an operator".

## Building a deck

Needs Node.js and npm.

```sh
cd 2026-ldapcon-slaptain
npm ci
npm run dev          # live preview in the browser
```

Other targets, all run from inside a talk directory:

| Command | Result |
|---|---|
| `npm run check` | Builds the deck into a temp dir and reports only real errors. |
| `npm run build` | Static site in `dist/`. |
| `npm run portable` | One self-contained `dist-single/index.html` that works offline from `file://`. |
| `npm run pdf` / `npm run pdf-clicks` | PDF export, one page per slide / one page per click step. |
| `npm run pptx` | PowerPoint export (slides as images). |
| `npm run flashdrive` | Portable HTML, PDF and PPTX together in `flashdrive/`. |

PDF and PPTX exports drive a headless browser. They use Playwright's Chromium
(`npx playwright-chromium install chromium`) or a Chromium/Chrome already on the
host.

## License

[CC BY 4.0](LICENSE). You may share and adapt the decks, including
commercially, as long as you give credit.
