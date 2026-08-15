--- oblsk_admin server: Organisations tab NUI handlers. Every mutation
--- replies with the full refreshed org list (OrganizationService.list())
--- rather than a partial patch -- the admin panel's org count is small
--- (tens, not thousands), so resending everything is simpler and can't
--- drift from what create/removeDepartment/etc. actually did.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function replyWithList(player)
    player:emit('admin:client:organisations-reply', { orgs = OrganizationService.list() })
end

Obelisk.onClient('admin:server:organisations-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-create', function(player, data)
    if not isAdmin(player) then return end
    local orgId = OrganizationService.create(data.name or 'New organisation')
    local ok, reason = OrganizationService.setDetails(orgId, { shortCode = data.shortCode, colour = data.colour, type = data.type or 'Government' })
    if not ok then
        NotificationService.error(player, 'Organisations', reason)
    end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-setDetails', function(player, data)
    if not isAdmin(player) then return end
    if data.name and data.name ~= '' then
        OrganizationService.rename(data.orgId, data.name)
    end
    local ok, reason = OrganizationService.setDetails(data.orgId, { shortCode = data.shortCode, colour = data.colour, type = data.type })
    if not ok then
        NotificationService.error(player, 'Organisations', reason)
    end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-addDepartment', function(player, data)
    if not isAdmin(player) then return end
    OrganizationService.addDepartment(data.orgId, data.name)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-removeDepartment', function(player, data)
    if not isAdmin(player) then return end
    OrganizationService.removeDepartment(data.deptId)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-addRank', function(player, data)
    if not isAdmin(player) then return end
    OrganizationService.addRank(data.orgId, data.name, data.grade or 0)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-removeRank', function(player, data)
    if not isAdmin(player) then return end
    OrganizationService.removeRank(data.rankId)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-addContactNumber', function(player, data)
    if not isAdmin(player) then return end
    OrganizationService.addContactNumber(data.orgId, data.number, data.label)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-removeContactNumber', function(player, data)
    if not isAdmin(player) then return end
    OrganizationService.removeContactNumber(data.contactId)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:organisations-toggleContactNumber', function(player, data)
    if not isAdmin(player) then return end
    OrganizationService.toggleContactNumber(data.contactId, data.enabled)
    replyWithList(player)
end)
