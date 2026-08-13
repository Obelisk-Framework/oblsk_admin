--- oblsk_admin client: owns the panel's open/closed state explicitly.
--- WebView.toggleGlobalElement was previously used here, but that combined
--- with an unconditional WebView.focus() meant closing the panel also
--- re-grabbed NUI focus with nothing to interact with. We now track
--- `panelOpen` locally and only focus when actually opening, using
--- showGlobalElement/hideGlobalElement instead of toggling blindly.
---
--- Known limitation: a bare ESC-close (core's global ESC watcher, not this
--- plugin's own close button) has no Lua-side notification, so `panelOpen`
--- can drift to true after an ESC-close. The next keybind press will then
--- try to "close" an already-hidden panel -- a harmless no-op
--- (hideGlobalElement on something already hidden) -- rather than opening
--- it. A real fix needs a core framework query API for global-element
--- visibility; out of scope for this fix pass.
local panelOpen = false

Obelisk.onClient('admin:client:toggle-panel', function()
    panelOpen = not panelOpen
    if panelOpen then
        WebView.showGlobalElement('admin')
        WebView.focus()
    else
        WebView.hideGlobalElement('admin')
    end
end)

--- Fired by the panel's own Close button (web/AdminPanel.vue), instead of
--- the generic 'core:client:close' NUI callback, so this plugin's local
--- `panelOpen` state stays in sync with what's actually hidden.
WebView.on('admin:client:close-panel', function()
    panelOpen = false
    WebView.hideGlobalElement('admin')
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
