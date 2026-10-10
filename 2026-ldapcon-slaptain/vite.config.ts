import { defineConfig } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'
import { readFileSync, writeFileSync, existsSync, rmSync, readdirSync, statSync } from 'node:fs'
import { join, extname, relative, resolve, sep } from 'node:path'

// Portable mode (SLIDEV_PORTABLE=1, set by `npm run portable`):
// inline EVERYTHING — JS, CSS, fonts, images — into one self-contained
// index.html that runs from file:// with no server and no network.
const portable = process.env.SLIDEV_PORTABLE === '1'

// Slidev forces output.manualChunks, which is incompatible with the
// single-file inlining (codeSplitting must be off). Strip it post-merge.
const stripManualChunks = {
  name: 'strip-manual-chunks',
  enforce: 'post' as const,
  configResolved(config: any) {
    const out = config.build?.rollupOptions?.output
    const outs = Array.isArray(out) ? out : [out].filter(Boolean)
    for (const o of outs) {
      delete o.manualChunks
      o.inlineDynamicImports = true
    }
  },
}

const MIME: Record<string, string> = {
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.avif': 'image/avif',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
  '.mp4': 'video/mp4',
  '.webm': 'video/webm',
  '.pdf': 'application/pdf',
}

const MAX_INLINE = 24 * 1024 * 1024 // per asset; keeps one runaway video out

// Files under public/ are copied verbatim by Vite and referenced by absolute
// path (src="/diagram.svg"). assetsInlineLimit does NOT apply to them, so
// without this they stay separate files next to index.html — which silently
// breaks every image as soon as you ship index.html alone (e.g. flashdrive/).
//
// This runs after the bundle is written, rewrites those references in the
// emitted HTML to data: URIs, and removes the now-unused copies.
const inlinePublicAssets = () => {
  // Closure state — inside Rollup/Vite hooks `this` is the plugin context,
  // not the plugin object, so state cannot live on the object literal.
  let outDir = ''
  let publicDir = ''

  return {
    name: 'inline-public-assets',
    enforce: 'post' as const,
    apply: 'build' as const,
    configResolved(config: any) {
      outDir = resolve(config.root ?? process.cwd(), config.build.outDir)
      publicDir = config.publicDir
    },
    closeBundle() {
      if (!outDir || !publicDir || !existsSync(publicDir)) return

      // Every file under public/, keyed by the path the deck references it by.
      const files: string[] = []
      const walk = (dir: string) => {
        for (const e of readdirSync(dir)) {
          const p = join(dir, e)
          statSync(p).isDirectory() ? walk(p) : files.push(p)
        }
      }
      walk(publicDir)

      for (const html of ['index.html', '404.html']) {
        const htmlPath = join(outDir, html)
        if (!existsSync(htmlPath)) continue
        let src = readFileSync(htmlPath, 'utf8')
        let inlined = 0

        for (const file of files) {
          const rel = relative(publicDir, file).split(sep).join('/')
          const mime = MIME[extname(rel).toLowerCase()]
          if (!mime) continue

          // Both the absolute form and the `--base ./` rewritten form.
          const refs = [`"/${rel}"`, `"./${rel}"`, `'/${rel}'`, `'./${rel}'`]
          const present = refs.filter((r) => src.includes(r))
          if (!present.length) continue

          const size = statSync(file).size
          if (size > MAX_INLINE) {
            console.warn(`  [portable] NOT inlined (${(size / 1e6).toFixed(1)} MB): ${rel}`)
            continue
          }

          const uri = `data:${mime};base64,${readFileSync(file).toString('base64')}`
          for (const r of present) {
            const q = r[0]
            src = src.split(r).join(`${q}${uri}${q}`)
          }
          inlined++
        }

        writeFileSync(htmlPath, src)
        if (inlined) console.log(`  [portable] ${html}: inlined ${inlined} public asset(s)`)
      }

      // The copies are dead weight now, and leaving them suggests index.html
      // still needs them.
      for (const file of files) {
        const rel = relative(publicDir, file)
        const copied = join(outDir, rel)
        if (existsSync(copied) && MIME[extname(rel).toLowerCase()]) rmSync(copied)
      }
    },
  }
}

export default defineConfig({
  plugins: portable ? [stripManualChunks, viteSingleFile(), inlinePublicAssets()] : [],
  // Inline fonts/images as base64 in portable mode (100 MB ceiling).
  build: portable ? { assetsInlineLimit: 100 * 1024 * 1024 } : {},
})
