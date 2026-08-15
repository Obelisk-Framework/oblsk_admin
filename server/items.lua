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
