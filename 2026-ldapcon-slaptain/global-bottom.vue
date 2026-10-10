<!--
  Global bottom layer:
  - click-to-zoom overlay for all images in slides. Click any <img> to view
    fullscreen, click overlay or press Escape to close.
  - legacy fallback for the code-block copy button. Slidev copies via VueUse
    useClipboard(), i.e. navigator.clipboard, which only exists in a secure
    context (https or localhost). Presenting from file:// — the portable
    flashdrive build — or over http://<LAN-IP> leaves it undefined, so the
    button silently does nothing. Here we detect that case and copy with the
    deprecated-but-universally-available execCommand path instead.
-->
<template>
  <div
    v-if="zoomed"
    class="zoom-overlay"
    @click="zoomed = false"
  >
    <img :src="zoomSrc" class="zoom-img" />
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
// Self-hosted fonts, inlined into the portable build (see fonts.css)
import './fonts.css'

const zoomed = ref(false)
const zoomSrc = ref('')

function handleClick(e) {
  // Find the closest img inside the slide content
  const img = e.target.closest('img')
  if (!img || !img.src) return
  // Don't zoom the overlay image itself
  if (img.classList.contains('zoom-img')) return
  // Only zoom images that look like plots (SVG/PNG/PDF paths, not tiny icons)
  if (!img.src.match(/\.(svg|png|jpg|jpeg)(\?|$)/i)) return

  zoomSrc.value = img.src
  zoomed.value = true
  e.preventDefault()
  e.stopPropagation()
}

// execCommand('copy') works in insecure contexts, where navigator.clipboard
// does not exist at all. Selection is saved and restored so a copy does not
// clobber whatever the presenter had selected.
function legacyCopy(text) {
  const ta = document.createElement('textarea')
  ta.value = text
  ta.setAttribute('readonly', '')
  ta.style.cssText = 'position:fixed;top:0;left:0;width:1px;height:1px;opacity:0;pointer-events:none'
  document.body.appendChild(ta)

  const sel = document.getSelection()
  const previous = sel && sel.rangeCount > 0 ? sel.getRangeAt(0) : null

  ta.select()
  ta.setSelectionRange(0, ta.value.length)

  let ok = false
  try {
    ok = document.execCommand('copy')
  }
  catch {
    ok = false
  }

  document.body.removeChild(ta)
  if (previous && sel) {
    sel.removeAllRanges()
    sel.addRange(previous)
  }
  return ok
}

function flash(btn, ok) {
  // Slidev's own `copied` state does not flip when its write failed, so give
  // our own feedback: blue for copied, amber if even the fallback refused.
  const cls = ok ? 'copy-ok' : 'copy-fail'
  btn.classList.add(cls)
  setTimeout(() => btn.classList.remove(cls), 900)
}

// Runs in addition to Slidev's own handler, not instead of it. Copying the same
// text twice is harmless; the point is that at least one of the two paths works.
// navigator.clipboard is rejected in an unfocused iframe (presenter mode) and
// absent outside a secure context, and neither failure is visible to the user.
function handleCopy(e) {
  const btn = e.target.closest && e.target.closest('.slidev-code-copy')
  if (!btn) return

  const wrapper = btn.closest('.slidev-code-wrapper')
  const code = wrapper && wrapper.querySelector('.slidev-code')
  const text = code && code.textContent
  if (!text) return

  // execCommand first, deliberately: it is synchronous, so it runs inside the
  // click gesture. An async clipboard rejection only arrives after this handler
  // has returned, which is a worse place to start a fallback from.
  if (legacyCopy(text)) {
    flash(btn, true)
    return
  }

  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(
      () => flash(btn, true),
      () => flash(btn, false),
    )
  }
  else {
    flash(btn, false)
  }
}

function handleKeydown(e) {
  if (e.key === 'Escape' && zoomed.value) {
    zoomed.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleCopy, true)
  document.addEventListener('click', handleClick, true)
  document.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  document.removeEventListener('click', handleCopy, true)
  document.removeEventListener('click', handleClick, true)
  document.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
.zoom-overlay {
  position: fixed;
  inset: 0;
  z-index: 99999;
  background: rgba(0, 0, 0, 0.92);
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: zoom-out;
}
.zoom-img {
  max-width: 55vw;
  max-height: 45vh;
  object-fit: contain;
}
</style>

<!-- Unscoped: the copy button lives outside this component's tree. -->
<style>
/*
  Slidev's own button is `opacity-0 group-hover:opacity-20` with a p-2 w-8 h-8
  icon, i.e. a 16px glyph at 20% opacity. On a projector — and on a mirrored
  display, where the canvas is scaled down further — that is invisible, and the
  live-demo slides need the presenter to actually find and hit it. Still hidden
  until the block is hovered, so nothing changes on the rendered slide.
*/
.slidev-code-wrapper:hover .slidev-code-copy {
  opacity: 0.85 !important;
}
.slidev-code-copy svg {
  width: 2.5rem;
  height: 2.5rem;
  padding: 0.45rem;
}

.slidev-code-copy.copy-ok {
  opacity: 1 !important;
  color: #60a5fa;
}
.slidev-code-copy.copy-fail {
  opacity: 1 !important;
  color: #fbbf24;
}
</style>
