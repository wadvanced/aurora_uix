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

export { Hooks }
