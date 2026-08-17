-- core/plugins/oblsk_admin/server/players.lua
--- oblsk_admin server: Players tab NUI handlers. Reads live server state
--- (GetPlayers()), not a database table -- there's nothing to persist for
--- an online-player list.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function listPlayers()
    local rows = {}
    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        local characterId = CharacterService.sessionCharacters[playerId]
        local character = characterId and Character:find(characterId)
        local coords = GetEntityCoords(GetPlayerPed(playerId))

        table.insert(rows, {
            source = playerId,
            name = GetPlayerName(playerId),
            characterName = character and (character.attributes.first_name .. ' ' .. character.attributes.last_name) or nil,
            ping = GetPlayerPing(playerId),
            coords = { x = coords.x, y = coords.y, z = coords.z },
        })
    end
    return rows
end

local function replyWithList(player)
    player:emit('admin:client:players-reply', { players = listPlayers() })
end

Obelisk.onClient('admin:server:players-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:players-teleport-to-player', function(player, data)
    if not isAdmin(player) then return end
    local targetPed = GetPlayerPed(data.targetSource)
    if targetPed == 0 then return end
    local coords = GetEntityCoords(targetPed)
    SetEntityCoords(GetPlayerPed(player:getSource()), coords.x, coords.y, coords.z)
end)

Obelisk.onClient('admin:server:players-bring-player', function(player, data)
    if not isAdmin(player) then return end
    local adminCoords = GetEntityCoords(GetPlayerPed(player:getSource()))
    local targetPed = GetPlayerPed(data.targetSource)
    if targetPed == 0 then return end
    SetEntityCoords(targetPed, adminCoords.x, adminCoords.y, adminCoords.z)
end)

Obelisk.onClient('admin:server:players-kick', function(player, data)
    if not isAdmin(player) then return end
    local accountId = AccountService.getAccountId(data.targetSource)
    if accountId then
        AccountService.logKick(accountId, data.reason or 'No reason given', tostring(player:getSource()))
    end
    DropPlayer(data.targetSource, 'Kicked: ' .. (data.reason or 'No reason given'))
    replyWithList(player)
end)

Obelisk.onClient('admin:server:players-spectate', function(player, data)
    if not isAdmin(player) then return end
    NotificationService.info(player, 'Players', 'Spectate mode is not implemented yet.')
end)
