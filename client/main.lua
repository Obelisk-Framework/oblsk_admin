--- oblsk_admin client: owns the panel's open/closed state explicitly.
--- WebView.toggleGlobalElement was previously used here, but that combined
--- with an unconditional WebView.focus() meant closing the panel also
--- re-grabbed NUI focus with nothing to interact with. We now track
--- `panelOpen` locally and only focus when actually opening, using
--- showGlobalElement/hideGlobalElement instead of toggling blindly.
---
--- Both close paths also call WebView.hide() (not just hideGlobalElement)
--- so NUI focus is actually released -- hideGlobalElement is a pure
--- SendNUIMessage with no setFocus call, so without this the player was
--- left with a cursor and no UI to click on.
---
--- ESC (core's global watcher) closes the panel with no Lua-side
--- notification, so `panelOpen` can drift to true after an ESC-close.
--- Resynced here on every keybind press via IsNuiFocused(): ESC always
--- drops focus, so if we think the panel is open but focus is gone, it was
--- closed by ESC and the next press should open it, not try to close it.
local panelOpen = false

Obelisk.onClient('admin:client:toggle-panel', function()
    if panelOpen and not IsNuiFocused() then
        panelOpen = false
    end

    panelOpen = not panelOpen
    if panelOpen then
        WebView.showGlobalElement('admin')
        WebView.focus()
    else
        WebView.hideGlobalElement('admin')
        WebView.hide()
    end
end)

--- Fired by the panel's own Close button (web/AdminPanel.vue), instead of
--- the generic 'core:client:close' NUI callback, so this plugin's local
--- `panelOpen` state stays in sync with what's actually hidden.
WebView.on('admin:client:close-panel', function()
    panelOpen = false
    WebView.hideGlobalElement('admin')
    WebView.hide()
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

-- Thin relays for the Players/Moderation/Vehicles/Items tabs, same pattern
-- as ORG_RELAYS above: every admin:client:<tab>-<verb> NUI event forwards
-- verbatim to the matching admin:server:<tab>-<verb> handler.
local TAB_RELAYS = {
    'players-list', 'players-teleport-to-player', 'players-bring-player', 'players-kick', 'players-spectate',
    'moderation-list', 'moderation-ban', 'moderation-unban', 'moderation-warn', 'moderation-kick',
    'vehicles-list', 'vehicles-delete', 'vehicles-teleport-to-admin',
    'items-list', 'items-update', 'items-create', 'items-give',
    'printers-list', 'printers-create', 'printers-update', 'printers-delete', 'printers-refill',
    'jobs-list', 'jobs-detail', 'jobs-create', 'jobs-update', 'jobs-delete',
    'jobs-upsert-level', 'jobs-delete-level',
    'jobs-upsert-task', 'jobs-delete-task',
    'jobs-upsert-route', 'jobs-delete-route',
}
for _, name in ipairs(TAB_RELAYS) do
    WebView.on('admin:client:' .. name, function(data)
        Obelisk.emitServer('admin:server:' .. name, data)
    end)
end

local TAB_REPLIES = { 'players-reply', 'moderation-reply', 'vehicles-reply', 'items-reply', 'printers-reply', 'jobs-reply', 'jobs-detail-reply' }
for _, name in ipairs(TAB_REPLIES) do
    Obelisk.onClient('admin:client:' .. name, function(payload)
        SendNUIMessage({ eventname = 'admin:client:' .. name, args = { payload } })
    end)
end
