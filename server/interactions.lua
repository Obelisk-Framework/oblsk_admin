-- core/plugins/oblsk_admin/server/interactions.lua
--- oblsk_admin server: Interactions tab NUI handlers -- a generic
--- pass-through to whatever interaction types plugins have registered via
--- core's InteractionTypeService (oblsk_gasstation's 'gasstation',
--- oblsk_mechanic's 'mechanic', etc). Every interaction is always created
--- through its owning type's `create` hook, which creates both the raw
--- `interactions` row and the type-specific row together -- there is no
--- "plain"/bare-interaction concept, an interaction always belongs to a
--- registered strategy. oblsk_admin has no bespoke knowledge of any of
--- those plugins' internals -- see InteractionTypeService.listForAdmin/get.
--- Every mutation replies with the full refreshed list, same posture as
--- items.lua/organisations.lua.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

--------------------------------------------------------------------------------
-- Gas stations - only the stock sub-editor stays bespoke (see Part 5's
-- comment in InteractionsTab.vue for why this wasn't generalized further).
-- Station list/create/update/delete now go through the generic
-- interactionType-* handlers below; stock mutations reply through the same
-- generic 'interactionType-reply' event (typeKey='gasstation') so the
-- already-generic selected-item panel picks up the refreshed stock list.
--------------------------------------------------------------------------------

local function replyGasStationsGeneric(player)
    player:emit('admin:client:interactionType-reply', { typeKey = 'gasstation', items = GasStationService.listStationsForAdmin() })
end

Obelisk.onClient('admin:server:gasstation-stock-add', function(player, data)
    if not isAdmin(player) then return end
    GasStationService.addStock(data.stationId, data)
    replyGasStationsGeneric(player)
end)

Obelisk.onClient('admin:server:gasstation-stock-update', function(player, data)
    if not isAdmin(player) then return end
    GasStationService.updateStock(data.stockId, data)
    replyGasStationsGeneric(player)
end)

Obelisk.onClient('admin:server:gasstation-stock-remove', function(player, data)
    if not isAdmin(player) then return end
    GasStationService.removeStock(data.stockId)
    replyGasStationsGeneric(player)
end)

Obelisk.onClient('admin:server:gasstation-fuelTypes-list', function(player)
    if not isAdmin(player) then return end
    player:emit('admin:client:gasstation-fuelTypes-reply', { fuelTypes = GasStationService.listFuelTypes() })
end)

--------------------------------------------------------------------------------
-- Generic interaction types - dynamic replacement for the old bespoke
-- gasstation-*/mechanic-* CRUD handlers above. Any plugin that has called
-- InteractionTypeService.register(...) (oblsk_gasstation, oblsk_mechanic,
-- future plugins) gets list/create/update/delete for free here, with zero
-- oblsk_admin-side knowledge of what that type actually is.
--
-- `data.fields` carries the type's declared extra fields (see
-- InteractionTypeService's `fields` schema) merged with the base interaction
-- fields (x/y/z/range/label) needed to place/move the world prompt -- every
-- current descriptor's create/update hook expects one flat table containing
-- both, so no further reshaping happens here.
--------------------------------------------------------------------------------

Obelisk.onClient('admin:server:interactionTypes-list', function(player)
    if not isAdmin(player) then return end
    player:emit('admin:client:interactionTypes-reply', { types = InteractionTypeService.listForAdmin() })
end)

Obelisk.onClient('admin:server:interactionType-list', function(player, data)
    if not isAdmin(player) then return end
    local descriptor = InteractionTypeService.get(data.typeKey)
    if not descriptor then return end
    player:emit('admin:client:interactionType-reply', { typeKey = data.typeKey, items = descriptor.list() })
end)

Obelisk.onClient('admin:server:interactionType-create', function(player, data)
    if not isAdmin(player) then return end
    local descriptor = InteractionTypeService.get(data.typeKey)
    if not descriptor then return end
    descriptor.create(data.fields or {})
    player:emit('admin:client:interactionType-reply', { typeKey = data.typeKey, items = descriptor.list() })
end)

Obelisk.onClient('admin:server:interactionType-update', function(player, data)
    if not isAdmin(player) then return end
    local descriptor = InteractionTypeService.get(data.typeKey)
    if not descriptor then return end
    descriptor.update(data.id, data.fields or {})
    player:emit('admin:client:interactionType-reply', { typeKey = data.typeKey, items = descriptor.list() })
end)

Obelisk.onClient('admin:server:interactionType-delete', function(player, data)
    if not isAdmin(player) then return end
    local descriptor = InteractionTypeService.get(data.typeKey)
    if not descriptor then return end
    descriptor.delete(data.id)
    player:emit('admin:client:interactionType-reply', { typeKey = data.typeKey, items = descriptor.list() })
end)
