-- core/plugins/oblsk_admin/server/items.lua
--- oblsk_admin server: Items tab NUI handlers.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

--- ItemService.listBaseItems() reads straight through QueryBuilder, bypassing
--- the BaseItem model layer, so its `data`/`actions = 'json'` casts never run
--- — those columns may still be raw JSON strings depending on the DB driver
--- (same caveat InventoryService.lua's decodeRowData documents for the same
--- raw-QueryBuilder pattern). The Actions editor needs `.actions` as a real
--- table, so decode both json columns in place before sending the list down.
--- @param row table
--- @param field string
local function decodeJsonField(row, field)
    if row and type(row[field]) == 'string' then
        local ok, decoded = pcall(json.decode, row[field])
        row[field] = ok and decoded or nil
    end
    return row
end

local function replyWithList(player)
    local list = ItemService.listBaseItems()
    for _, item in ipairs(list) do
        decodeJsonField(item, 'data')
        decodeJsonField(item, 'actions')
    end
    player:emit('admin:client:items-reply', { items = list })
end

Obelisk.onClient('admin:server:items-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:items-update', function(player, data)
    if not isAdmin(player) then return end
    ItemService.updateBaseItem(data.baseItemId, data.attributes or {})
    replyWithList(player)
end)

Obelisk.onClient('admin:server:items-create', function(player, data)
    if not isAdmin(player) then return end
    local id, reason = ItemService.createBaseItem(data.attributes or {}, data.bindingKey)
    if not id then
        NotificationService.error(player, 'Items', reason)
    end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:items-give', function(player, data)
    if not isAdmin(player) then return end
    local ok, reason = ItemService.giveToPlayer(data.targetSource, data.baseItemId, data.amount)
    if ok then
        NotificationService.success(player, 'Items', 'Item given.')
        local targetPlayer = PlayerService.get(data.targetSource)
        if targetPlayer then
            NotificationService.info(targetPlayer, 'Items', 'You received an item from staff.')
        end
    else
        NotificationService.error(player, 'Items', reason)
    end
    replyWithList(player)
end)

--- Mints a short-lived upload token for the selected item's icon image. The
--- browser-side fetch (ItemsTab.vue) posts the returned token straight to
--- POST /storage/upload; nothing else server-side is needed to persist the
--- resulting URL — the Vue side calls the existing items-update handler with
--- { attributes: { icon: url } } once the upload completes.
Obelisk.onClient('admin:server:items-icon-upload-mint', function(player, data)
    if not isAdmin(player) then return end
    local key = 'items/' .. tostring(data.baseItemId) .. '/icon-' .. os.time() .. '.png'
    local token = Storage.mintUploadToken(key, 'image/png')
    player:emit('admin:client:items-icon-upload-token-reply', { token = token, key = key })
end)

local function replyWithBindings(player)
    player:emit('admin:client:items-bindings-reply', { bindings = ItemService.listBindings(), requiredKeys = ItemService.getRequiredBindingKeys() })
end

Obelisk.onClient('admin:server:items-bindings-list', function(player)
    if not isAdmin(player) then return end
    replyWithBindings(player)
end)

Obelisk.onClient('admin:server:items-bindings-set', function(player, data)
    if not isAdmin(player) then return end
    ItemService.setBinding(data.key, data.baseItemId)
    replyWithBindings(player)
end)

Obelisk.onClient('admin:server:items-bindings-clear', function(player, data)
    if not isAdmin(player) then return end
    ItemService.clearBinding(data.key)
    replyWithBindings(player)
end)

Obelisk.onClient('admin:server:items-actions-list', function(player)
    if not isAdmin(player) then return end
    player:emit('admin:client:items-actions-reply', { actions = ItemService.listAvailableActions() })
end)

Obelisk.onClient('admin:server:items-update-actions', function(player, data)
    if not isAdmin(player) then return end
    ItemService.setBaseItemActions(data.baseItemId, data.actions or {})
    replyWithList(player)
end)
