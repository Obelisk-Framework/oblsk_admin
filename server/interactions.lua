-- core/plugins/oblsk_admin/server/interactions.lua
--- oblsk_admin server: Interactions tab NUI handlers -- plain `interactions`
--- rows plus a generic pass-through to whatever interaction types plugins
--- have registered via core's InteractionTypeService (oblsk_gasstation's
--- 'gasstation', oblsk_mechanic's 'mechanic', etc). oblsk_admin no longer
--- has any bespoke knowledge of those plugins' internals -- see
--- InteractionTypeService.listForAdmin/get. Every mutation replies with the
--- full refreshed list, same posture as items.lua/organisations.lua.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

--- Tables (in priority order) whose `interaction_id` column may reference an
--- `interactions` row, and the tag reported to the admin UI for each.
local ATTACHMENT_TABLES = {
    { table = 'gasstation_stations', tag = 'gasstation' },
    { table = 'mechanic_stations', tag = 'mechanic' },
    { table = 'shops', tag = 'shop' },
    { table = 'vendingmachine_shops', tag = 'vendingmachine' },
    { table = 'tuner_shops', tag = 'tuner' },
}

--- Best-effort read-only classification of which plugin (if any) owns a
--- given `interactions` row, by checking each known *_id-referencing table
--- for a row pointing at it. Not exhaustive beyond the tables above.
--- @param interactionId number
--- @return string tag one of 'gasstation'/'mechanic'/'shop'/'vendingmachine'/'tuner'/'other'
local function classifyInteraction(interactionId)
    for _, entry in ipairs(ATTACHMENT_TABLES) do
        local row = QueryBuilder.new(entry.table):where('interaction_id', interactionId):firstSync()
        if row then
            return entry.tag
        end
    end
    return 'other'
end

--- @param interactionId number
--- @return boolean true if any known plugin table still references this row
local function isAttached(interactionId)
    return classifyInteraction(interactionId) ~= 'other'
end

--- @return table[] every `interactions` row, tagged with `attachedTo`
local function listInteractionsForAdmin()
    local rows = QueryBuilder.new('interactions'):getSync()
    local out = {}
    for _, row in ipairs(rows) do
        table.insert(out, {
            id = row.id,
            x = row.x,
            y = row.y,
            z = row.z,
            range = row.range,
            label = row.label,
            enabled = row.enabled,
            attachedTo = classifyInteraction(row.id),
        })
    end
    return out
end

local function replyInteractions(player)
    player:emit('admin:client:interactions-reply', { interactions = listInteractionsForAdmin() })
end

Obelisk.onClient('admin:server:interactions-list', function(player)
    if not isAdmin(player) then return end
    replyInteractions(player)
end)

Obelisk.onClient('admin:server:interactions-create', function(player, data)
    if not isAdmin(player) then return end
    local id = QueryBuilder.new('interactions'):insert({
        x = data.x, y = data.y, z = data.z,
        range = data.range or 2.0,
        label = data.label or 'Interact',
    })
    InteractionService.registerFromDb(id, {
        x = data.x, y = data.y, z = data.z,
        range = data.range or 2.0,
        label = data.label or 'Interact',
    })
    replyInteractions(player)
end)

Obelisk.onClient('admin:server:interactions-update', function(player, data)
    if not isAdmin(player) then return end
    local patch = {}
    if data.x ~= nil then patch.x = data.x end
    if data.y ~= nil then patch.y = data.y end
    if data.z ~= nil then patch.z = data.z end
    if data.range ~= nil then patch.range = data.range end
    if data.label ~= nil then patch.label = data.label end

    QueryBuilder.new('interactions'):where('id', data.id):update(patch)
    InteractionService.updateByDbId(data.id, patch)
    replyInteractions(player)
end)

Obelisk.onClient('admin:server:interactions-delete', function(player, data)
    if not isAdmin(player) then return end
    local tag = classifyInteraction(data.id)
    if tag ~= 'other' then
        NotificationService.error(player, 'Interactions', 'Delete the owning ' .. tag .. ' station first.')
        replyInteractions(player)
        return
    end

    InteractionService.unregisterByDbId(data.id)
    QueryBuilder.new('interactions'):where('id', data.id):delete()
    replyInteractions(player)
end)

Obelisk.onClient('admin:server:interactions-setEnabled', function(player, data)
    if not isAdmin(player) then return end
    QueryBuilder.new('interactions'):where('id', data.id):update({ enabled = data.enabled })
    InteractionService.setEnabledByDbId(data.id, data.enabled)
    replyInteractions(player)
end)

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
