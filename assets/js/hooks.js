let Hooks = {}

Hooks.AuixThemeName = {
  mounted() {
    this.handleEvent("set_html_theme_name", ({ theme_name }) => {
      document.documentElement.setAttribute("data-theme-name", theme_name)
    })
  }
}

window.addEventListener("phx:auix_download", ({ detail: { name, data } }) => {
  const bytes = Uint8Array.from(atob(data), c => c.charCodeAt(0))
  const blob = new Blob([bytes])
  const url = URL.createObjectURL(blob)
  const a = document.createElement("a")
  a.href = url
  a.download = name
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
})

export { Hooks }
