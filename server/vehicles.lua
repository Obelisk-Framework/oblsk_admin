-- core/plugins/oblsk_admin/server/vehicles.lua
--- oblsk_admin server: Vehicles tab NUI handlers.
local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function replyWithList(source)
    Obelisk.emitClient('admin:client:vehicles-reply', source, { vehicles = VehicleService.listAll() })
end

Obelisk.onServer('admin:server:vehicles-list', function()
    local source = source
    if not isAdmin(source) then return end
    replyWithList(source)
end)

Obelisk.onServer('admin:server:vehicles-delete', function(data)
    local source = source
    if not isAdmin(source) then return end
    VehicleService.deleteById(data.vehicleId)
    replyWithList(source)
end)

Obelisk.onServer('admin:server:vehicles-teleport-to-admin', function(data)
    local source = source
    if not isAdmin(source) then return end
    local adminCoords = GetEntityCoords(GetPlayerPed(source))
    local ok, reason = VehicleService.teleportToCoords(data.vehicleId, adminCoords)
    if not ok then
        NotificationService.error(source, 'Vehicles', reason)
    end
    replyWithList(source)
end)
