-- core/plugins/oblsk_admin/server/items.lua
--- oblsk_admin server: Items tab NUI handlers.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function replyWithList(player)
    player:emit('admin:client:items-reply', { items = ItemService.listBaseItems() })
end

Obelisk.onClient('admin:server:items-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:items-update', function(player, data)
    if not isAdmin(player) then return end
    local attributes = data.attributes or {}
    -- The admin UI sends the sentinel string '__clear__' for
    -- base_item_category_id when "None" is selected, since a JSON
    -- null round-trips as Lua nil and ItemService.updateBaseItem's
    -- whitelist loop treats a nil value as "field not provided" (no-op),
    -- not "clear this column". Translate the sentinel to Database.NULL,
    -- the sentinel QueryBuilder:update already understands.
    if attributes.base_item_category_id == '__clear__' then
        attributes.base_item_category_id = Database.NULL
    end
    ItemService.updateBaseItem(data.baseItemId, attributes)
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

local function replyWithCategories(player)
    player:emit('admin:client:categories-reply', { categories = ItemService.listCategories() })
end

Obelisk.onClient('admin:server:categories-list', function(player)
    if not isAdmin(player) then return end
    replyWithCategories(player)
end)

Obelisk.onClient('admin:server:categories-create', function(player, data)
    if not isAdmin(player) then return end
    local id, reason = ItemService.createCategory(data.attributes or {})
    if not id then
        NotificationService.error(player, 'Items', reason)
    end
    replyWithCategories(player)
end)

Obelisk.onClient('admin:server:categories-update', function(player, data)
    if not isAdmin(player) then return end
    local ok, reason = ItemService.updateCategory(data.categoryId, data.attributes or {})
    if not ok then
        NotificationService.error(player, 'Items', reason)
    end
    replyWithCategories(player)
end)

Obelisk.onClient('admin:server:categories-delete', function(player, data)
    if not isAdmin(player) then return end
    local ok, reason = ItemService.deleteCategory(data.categoryId)
    if not ok then
        NotificationService.error(player, 'Items', reason)
    end
    replyWithCategories(player)
end)

Obelisk.onClient('admin:server:items-update-category-data', function(player, data)
    if not isAdmin(player) then return end
    local ok, errors = ItemService.updateBaseItemCategoryData(data.baseItemId, data.values or {})
    if not ok then
        NotificationService.error(player, 'Items', table.concat(errors, ', '))
    end
    replyWithList(player)
end)
