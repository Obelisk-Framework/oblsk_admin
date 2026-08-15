-- core/plugins/oblsk_admin/server/moderation.lua
--- oblsk_admin server: Moderation tab NUI handlers. Bans persist through
--- the pre-existing `bans` table/AccountService.ban (already enforced at
--- connect via checkBan); warn/kick persist through the new
--- moderation_logs table/AccountService.warn/logKick.
local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function accountExists(accountId)
    return Account:findSync(accountId) ~= nil
end

local function replyWithLists(source)
    Obelisk.emitClient('admin:client:moderation-reply', source, {
        bans = AccountService.listBans(),
        logs = AccountService.listModerationLogs(),
    })
end

Obelisk.onServer('admin:server:moderation-list', function()
    local source = source
    if not isAdmin(source) then return end
    replyWithLists(source)
end)

Obelisk.onServer('admin:server:moderation-ban', function(data)
    local source = source
    if not isAdmin(source) then return end

    if not accountExists(data.accountId) then
        NotificationService.error(source, 'Moderation', 'No such account: ' .. tostring(data.accountId))
        return
    end

    local expiresAt = nil
    if data.durationHours and data.durationHours > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + data.durationHours * 3600)
    end

    AccountService.ban({ accountId = data.accountId }, data.reason or 'No reason given', tostring(source), expiresAt)

    -- A ban that doesn't remove the still-connected player is a broken ban.
    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if AccountService.getAccountId(playerId) == data.accountId then
            DropPlayer(playerId, 'Banned: ' .. (data.reason or 'No reason given'))
        end
    end

    replyWithLists(source)
end)

Obelisk.onServer('admin:server:moderation-unban', function(data)
    local source = source
    if not isAdmin(source) then return end
    AccountService.unban(data.banId)
    replyWithLists(source)
end)

Obelisk.onServer('admin:server:moderation-warn', function(data)
    local source = source
    if not isAdmin(source) then return end

    if not accountExists(data.accountId) then
        NotificationService.error(source, 'Moderation', 'No such account: ' .. tostring(data.accountId))
        return
    end

    AccountService.warn(data.accountId, data.reason or 'No reason given', tostring(source))

    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if AccountService.getAccountId(playerId) == data.accountId then
            NotificationService.warning(playerId, 'Warning', data.reason or 'No reason given')
        end
    end

    replyWithLists(source)
end)

Obelisk.onServer('admin:server:moderation-kick', function(data)
    local source = source
    if not isAdmin(source) then return end

    if not accountExists(data.accountId) then
        NotificationService.error(source, 'Moderation', 'No such account: ' .. tostring(data.accountId))
        return
    end

    AccountService.logKick(data.accountId, data.reason or 'No reason given', tostring(source))

    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if AccountService.getAccountId(playerId) == data.accountId then
            DropPlayer(playerId, 'Kicked: ' .. (data.reason or 'No reason given'))
        end
    end

    replyWithLists(source)
end)
