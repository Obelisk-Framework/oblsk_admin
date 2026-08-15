-- core/plugins/oblsk_admin/server/items.lua
--- oblsk_admin server: Items tab NUI handlers.
local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function replyWithList(source)
    Obelisk.emitClient('admin:client:items-reply', source, { items = ItemService.listBaseItems() })
end

Obelisk.onServer('admin:server:items-list', function()
    local source = source
    if not isAdmin(source) then return end
    replyWithList(source)
end)

Obelisk.onServer('admin:server:items-update', function(data)
    local source = source
    if not isAdmin(source) then return end
    ItemService.updateBaseItem(data.baseItemId, data.attributes or {})
    replyWithList(source)
end)

Obelisk.onServer('admin:server:items-create', function(data)
    local source = source
    if not isAdmin(source) then return end
    local id, reason = ItemService.createBaseItem(data.attributes or {})
    if not id then
        NotificationService.error(source, 'Items', reason)
    end
    replyWithList(source)
end)

Obelisk.onServer('admin:server:items-give', function(data)
    local source = source
    if not isAdmin(source) then return end
    local ok, reason = ItemService.giveToPlayer(data.targetSource, data.baseItemId, data.amount)
    if ok then
        NotificationService.success(source, 'Items', 'Item given.')
        NotificationService.info(data.targetSource, 'Items', 'You received an item from staff.')
    else
        NotificationService.error(source, 'Items', reason)
    end
    replyWithList(source)
end)
