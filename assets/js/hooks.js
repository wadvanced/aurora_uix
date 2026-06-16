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
    this.el.classList.add("auix-copyable-button--copied")
    setTimeout(() => this.el.classList.remove("auix-copyable-button--copied"), 1000)
  }
}

export { Hooks }
