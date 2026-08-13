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

-- Thin relays: every admin:client:organisations-* NUI event forwards
-- verbatim to the matching admin:server:organisations-* handler.
local ORG_RELAYS = {
    'organisations-list', 'organisations-create', 'organisations-setDetails',
    'organisations-addDepartment', 'organisations-removeDepartment',
    'organisations-addRank', 'organisations-removeRank',
    'organisations-addContactNumber', 'organisations-removeContactNumber',
    'organisations-toggleContactNumber',
}
for _, name in ipairs(ORG_RELAYS) do
    WebView.on('admin:client:' .. name, function(data)
        Obelisk.emitServer('admin:server:' .. name, data)
    end)
end

Obelisk.onClient('admin:client:organisations-reply', function(payload)
    SendNUIMessage({ eventname = 'admin:client:organisations-reply', args = { payload } })
end)
