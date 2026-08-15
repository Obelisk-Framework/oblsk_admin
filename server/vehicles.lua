-- core/plugins/oblsk_admin/server/vehicles.lua
--- oblsk_admin server: Vehicles tab NUI handlers.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function replyWithList(player)
    player:emit('admin:client:vehicles-reply', { vehicles = VehicleService.listAll() })
end

Obelisk.onClient('admin:server:vehicles-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:vehicles-delete', function(player, data)
    if not isAdmin(player) then return end
    VehicleService.deleteById(data.vehicleId)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:vehicles-teleport-to-admin', function(player, data)
    if not isAdmin(player) then return end
    local adminCoords = GetEntityCoords(GetPlayerPed(player:getSource()))
    local ok, reason = VehicleService.teleportToCoords(data.vehicleId, adminCoords)
    if not ok then
        NotificationService.error(player, 'Vehicles', reason)
    end
    replyWithList(player)
end)
