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

export { Hooks }
