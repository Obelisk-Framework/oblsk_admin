--- oblsk_admin client: toggles the panel's global element and NUI focus.
--- Visibility lives entirely on the Vue side (core/web/src/App.vue's
--- `registry` Map, keyed by the globalElements.js name), driven by the
--- `core:client:webview-toggleGlobalElement` NUI message that
--- WebView.toggleGlobalElement sends -- so this file carries no local
--- open/closed state of its own, nothing to drift out of sync with ESC
--- (WebView.closeAll, wired NUI-side in App.vue) or the panel's own close
--- button (Task 6, emits the generic 'core:client:close' NUI callback).
Obelisk.onClient('admin:client:toggle-panel', function()
    WebView.toggleGlobalElement('admin')
    WebView.focus()
end)
