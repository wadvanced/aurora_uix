let Hooks = {}

Hooks.AuixThemeName = {
  mounted() {
    this.handleEvent("set_html_theme_name", ({ theme_name }) => {
      document.documentElement.setAttribute("data-theme-name", theme_name)
    })
  }
}

if (!window.__auixDownloadListenerBound) {
  window.__auixDownloadListenerBound = true
  window.addEventListener("phx:auix_download", ({ detail: { name, data, content_type } }) => {
    const bytes = Uint8Array.from(atob(data), c => c.charCodeAt(0))
    const blob = content_type ? new Blob([bytes], { type: content_type }) : new Blob([bytes])
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = name
    a.rel = "noopener"
    a.click()
    // Defer teardown: revoking the object URL     
    // aborts the download, letting the click fall through to a navigation that
    // reverts the page.
    setTimeout(() => {
      URL.revokeObjectURL(url)
    }, 0)
  })
}

Hooks.AuixCopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => this.copy())
  },
  copy() {
    const targetId = this.el.getAttribute("data-auix-copy-target")
    const input = targetId && document.getElementById(targetId)
    if (!input) return
    const value = input.value ?? ""
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(value).then(() => this.flash())
    } else {
      input.focus()
      input.select()
      document.execCommand("copy")
      this.flash()
    }
  },
  flash() {
    const existing = document.querySelector(".auix-copyable-toast")
    if (existing) existing.remove()

    const message = this.el.getAttribute("data-auix-copied-message") || "Copied!"
    const toast = document.createElement("div")
    toast.className = "auix-copyable-toast"
    toast.textContent = message
    document.body.appendChild(toast)

    requestAnimationFrame(() => {
      requestAnimationFrame(() => toast.classList.add("auix-copyable-toast--visible"))
    })

    setTimeout(() => {
      toast.classList.remove("auix-copyable-toast--visible")
      toast.addEventListener("transitionend", () => toast.remove(), { once: true })
    }, 2000)
  }
}

Hooks.AuixCanvas = {
  mounted() {
    const canvas = this.el
    const input = document.getElementById(canvas.dataset.auixInputId)
    const clearBtn = document.getElementById(canvas.dataset.auixClearId)
    const ctx = canvas.getContext("2d")
    let drawing = false

    ctx.lineWidth = 2
    ctx.lineJoin = "round"
    ctx.lineCap = "round"

    const point = e => {
      const rect = canvas.getBoundingClientRect()
      const src = e.touches ? e.touches[0] : e
      return {
        x: (src.clientX - rect.left) * (canvas.width / rect.width),
        y: (src.clientY - rect.top) * (canvas.height / rect.height)
      }
    }

    const persist = () => {
      if (!input) return
      input.value = canvas.toDataURL("image/png")
      input.dispatchEvent(new Event("input", { bubbles: true }))
    }

    const start = e => {
      drawing = true
      const p = point(e)
      ctx.beginPath()
      ctx.moveTo(p.x, p.y)
      e.preventDefault()
    }
    const move = e => {
      if (!drawing) return
      const p = point(e)
      ctx.lineTo(p.x, p.y)
      ctx.stroke()
      e.preventDefault()
    }
    const end = () => {
      if (!drawing) return
      drawing = false
      persist()
    }

    canvas.addEventListener("mousedown", start)
    canvas.addEventListener("mousemove", move)
    window.addEventListener("mouseup", end)
    canvas.addEventListener("touchstart", start, { passive: false })
    canvas.addEventListener("touchmove", move, { passive: false })
    canvas.addEventListener("touchend", end)

    if (clearBtn) {
      clearBtn.addEventListener("click", () => {
        ctx.clearRect(0, 0, canvas.width, canvas.height)
        if (input) {
          input.value = ""
          input.dispatchEvent(new Event("input", { bubbles: true }))
        }
      })
    }

    if (input && input.value) {
      const img = new Image()
      img.onload = () => ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
      img.src = input.value
    }
  }
}

export { Hooks }
