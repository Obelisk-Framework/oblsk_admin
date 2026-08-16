--- oblsk_admin client: owns the panel's open/closed state explicitly.
--- The panel is a routed page ('/Admin'), not a global element, so unlike
--- Garage/Shop (only ever opened via a world interaction, closed by their
--- own X button/ESC) this one is also toggled by a keybind — the router
--- alone can't tell the Vue side "you're being closed" the way
--- hideGlobalElement used to, so a `panelOpen`/panel-open/panel-close
--- signal pair does that explicitly in both directions.
---
--- WebView.hide() releases NUI focus but, unlike hideGlobalElement, does
--- NOT hide a routed page's DOM (core/web/src/App.vue's webview-hide
--- handler only resets HUD edit mode) — so AdminPanel.vue must hide itself
--- in response to 'admin:client:panel-close', not rely on the webview call
--- alone.
---
--- ESC (core's global watcher) calls WebView.closeAll(), which only affects
--- global elements, never routed pages — so it does nothing for this panel.
--- AdminPanel.vue therefore listens for its own Escape keydown, same as
--- Shop.vue/Garage.vue do for their own panels.
local panelOpen = false

Obelisk.onClient('admin:client:toggle-panel', function()
    if panelOpen and not IsNuiFocused() then
        panelOpen = false
    end

    panelOpen = not panelOpen
    if panelOpen then
        WebView.openPage('/Admin')
        WebView.focus()
        WebView.emit('admin:client:panel-open', {})
    else
        WebView.emit('admin:client:panel-close', {})
        WebView.hide()
    end
end)

--- Fired by the panel's own Close button / Escape handler (web/AdminPanel.vue),
--- instead of the generic 'core:client:close' NUI callback, so this plugin's
--- local `panelOpen` state stays in sync with what's actually hidden.
WebView.on('admin:client:close-panel', function()
    panelOpen = false
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
    'baseVehicles-list', 'baseVehicles-create', 'baseVehicles-update', 'baseVehicles-delete', 'baseVehicles-fuelTypes-list',
    'items-list', 'items-update', 'items-create', 'items-give',
    'items-icon-upload-mint',
    'items-bindings-list', 'items-bindings-set', 'items-bindings-clear',
    'items-actions-list', 'items-update-actions',
    'printers-list', 'printers-create', 'printers-update', 'printers-delete', 'printers-refill',
    'jobs-list', 'jobs-detail', 'jobs-create', 'jobs-update', 'jobs-delete',
    'jobs-upsert-level', 'jobs-delete-level',
    'jobs-upsert-task', 'jobs-delete-task',
    'jobs-upsert-route', 'jobs-delete-route',
    'scheduler-list', 'scheduler-create', 'scheduler-update', 'scheduler-delete',
    'gasstation-stock-add', 'gasstation-stock-update', 'gasstation-stock-remove', 'gasstation-fuelTypes-list',
    'interactionTypes-list', 'interactionType-list', 'interactionType-create', 'interactionType-update', 'interactionType-delete',
    'safe-owners-link', 'safe-owners-unlink', 'safe-ownerCandidates-list', 'safe-transactions-list',
}
for _, name in ipairs(TAB_RELAYS) do
    WebView.on('admin:client:' .. name, function(data)
        Obelisk.emitServer('admin:server:' .. name, data)
    end)
end

local TAB_REPLIES = {
    'players-reply', 'moderation-reply', 'vehicles-reply', 'items-reply', 'printers-reply', 'jobs-reply', 'jobs-detail-reply', 'scheduler-reply',
    'gasstation-fuelTypes-reply',
    'baseVehicles-reply', 'baseVehicles-fuelTypes-reply',
    'interactionTypes-reply', 'interactionType-reply',
    'items-icon-upload-token-reply', 'items-bindings-reply', 'items-actions-reply',
    'safe-ownerCandidates-reply', 'safe-transactions-reply',
}
for _, name in ipairs(TAB_REPLIES) do
    Obelisk.onClient('admin:client:' .. name, function(payload)
        SendNUIMessage({ eventname = 'admin:client:' .. name, args = { payload } })
    end)
end

--- Not a plain relay: captures the admin's current position/heading and
--- pushes it straight to the NUI, for the Interactions tab's "use my
--- position" create/edit helpers (no create form otherwise has a way to
--- fill in coordinates).
WebView.on('admin:client:interactions-getMyCoords', function()
    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    SendNUIMessage({ eventname = 'admin:client:interactions-myCoords', args = { { x = coords.x, y = coords.y, z = coords.z, heading = heading } } })
end)

--- Not a plain relay: the NUI (CEF, a different origin) can't discover the
--- connected FiveM server's own ip:port itself, but needs an absolute URL to
--- POST an icon upload straight to this server's /storage/upload endpoint
--- (that endpoint lives on the game-server TCP port, not the nui:// resource
--- -file origin SendNUIMessage/WebView otherwise operate on). Mirrors the
--- interactions-getMyCoords pattern above: a client-Lua-computed value the
--- NUI has no other way to obtain.
WebView.on('admin:client:items-get-upload-endpoint', function()
    SendNUIMessage({ eventname = 'admin:client:items-upload-endpoint', args = { { endpoint = GetCurrentServerEndpoint() } } })
end)
