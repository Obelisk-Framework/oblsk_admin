-- core/plugins/oblsk_admin/server/moderation.lua
--- oblsk_admin server: Moderation tab NUI handlers. Bans persist through
--- the pre-existing `bans` table/AccountService.ban (already enforced at
--- connect via checkBan); warn/kick persist through the new
--- moderation_logs table/AccountService.warn/logKick.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function accountExists(accountId)
    return Account:find(accountId) ~= nil
end

local function replyWithLists(player)
    player:emit('admin:client:moderation-reply', {
        bans = AccountService.listBans(),
        logs = AccountService.listModerationLogs(),
    })
end

Obelisk.onClient('admin:server:moderation-list', function(player)
    if not isAdmin(player) then return end
    replyWithLists(player)
end)

Obelisk.onClient('admin:server:moderation-ban', function(player, data)
    if not isAdmin(player) then return end

    if not accountExists(data.accountId) then
        NotificationService.error(player, 'Moderation', 'No such account: ' .. tostring(data.accountId))
        return
    end

    local expiresAt = nil
    if data.durationHours and data.durationHours > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + data.durationHours * 3600)
    end

    AccountService.ban({ accountId = data.accountId }, data.reason or 'No reason given', tostring(player:getSource()), expiresAt)

    -- A ban that doesn't remove the still-connected player is a broken ban.
    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if AccountService.getAccountId(playerId) == data.accountId then
            DropPlayer(playerId, 'Banned: ' .. (data.reason or 'No reason given'))
        end
    end

    replyWithLists(player)
end)

Obelisk.onClient('admin:server:moderation-unban', function(player, data)
    if not isAdmin(player) then return end
    AccountService.unban(data.banId)
    replyWithLists(player)
end)

Obelisk.onClient('admin:server:moderation-warn', function(player, data)
    if not isAdmin(player) then return end

    if not accountExists(data.accountId) then
        NotificationService.error(player, 'Moderation', 'No such account: ' .. tostring(data.accountId))
        return
    end

    AccountService.warn(data.accountId, data.reason or 'No reason given', tostring(player:getSource()))

    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if AccountService.getAccountId(playerId) == data.accountId then
            local targetPlayer = PlayerService.get(playerId)
            if targetPlayer then
                NotificationService.warning(targetPlayer, 'Warning', data.reason or 'No reason given')
            end
        end
    end

    replyWithLists(player)
end)

Obelisk.onClient('admin:server:moderation-kick', function(player, data)
    if not isAdmin(player) then return end

    if not accountExists(data.accountId) then
        NotificationService.error(player, 'Moderation', 'No such account: ' .. tostring(data.accountId))
        return
    end

    AccountService.logKick(data.accountId, data.reason or 'No reason given', tostring(player:getSource()))

    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if AccountService.getAccountId(playerId) == data.accountId then
            DropPlayer(playerId, 'Kicked: ' .. (data.reason or 'No reason given'))
        end
    end

    replyWithLists(player)
end)
