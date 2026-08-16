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

--- base_vehicles catalog (vehicle model templates) -- a separate concern
--- from the owned-instance handlers above, mirroring oblsk_admin's Items tab
--- (base_items catalog vs. owned `items` rows).
local function replyWithBaseVehiclesList(player)
    player:emit('admin:client:baseVehicles-reply', { baseVehicles = VehicleService.listBaseVehicles() })
end

Obelisk.onClient('admin:server:baseVehicles-list', function(player)
    if not isAdmin(player) then return end
    replyWithBaseVehiclesList(player)
end)

Obelisk.onClient('admin:server:baseVehicles-create', function(player, data)
    if not isAdmin(player) then return end
    local id, reason = VehicleService.createBaseVehicle(data.attributes or {})
    if not id then
        NotificationService.error(player, 'Vehicles', reason)
    end
    replyWithBaseVehiclesList(player)
end)

Obelisk.onClient('admin:server:baseVehicles-update', function(player, data)
    if not isAdmin(player) then return end
    VehicleService.updateBaseVehicle(data.baseVehicleId, data.attributes or {})
    replyWithBaseVehiclesList(player)
end)

Obelisk.onClient('admin:server:baseVehicles-delete', function(player, data)
    if not isAdmin(player) then return end
    local ok, reason = VehicleService.deleteBaseVehicle(data.baseVehicleId)
    if not ok then
        NotificationService.error(player, 'Vehicles', reason)
    end
    replyWithBaseVehiclesList(player)
end)

Obelisk.onClient('admin:server:baseVehicles-fuelTypes-list', function(player)
    if not isAdmin(player) then return end
    player:emit('admin:client:baseVehicles-fuelTypes-reply', { fuelTypes = VehicleService.listFuelTypesForAdmin() })
end)
