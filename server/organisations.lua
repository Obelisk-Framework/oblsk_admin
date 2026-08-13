--- oblsk_admin server: Organisations tab NUI handlers. Every mutation
--- replies with the full refreshed org list (OrganizationService.list())
--- rather than a partial patch -- the admin panel's org count is small
--- (tens, not thousands), so resending everything is simpler and can't
--- drift from what create/removeDepartment/etc. actually did.
local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function replyWithList(source)
    Obelisk.emitClient('admin:client:organisations-reply', source, { orgs = OrganizationService.list() })
end

Obelisk.onServer('admin:server:organisations-list', function()
    local source = source
    if not isAdmin(source) then return end
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-create', function(data)
    local source = source
    if not isAdmin(source) then return end
    local orgId = OrganizationService.create(data.name or 'New organisation')
    local ok, reason = OrganizationService.setDetails(orgId, { shortCode = data.shortCode, colour = data.colour, type = data.type or 'Government' })
    if not ok then
        NotificationService.error(source, 'Organisations', reason)
    end
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-setDetails', function(data)
    local source = source
    if not isAdmin(source) then return end
    if data.name and data.name ~= '' then
        OrganizationService.rename(data.orgId, data.name)
    end
    local ok, reason = OrganizationService.setDetails(data.orgId, { shortCode = data.shortCode, colour = data.colour, type = data.type })
    if not ok then
        NotificationService.error(source, 'Organisations', reason)
    end
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-addDepartment', function(data)
    local source = source
    if not isAdmin(source) then return end
    OrganizationService.addDepartment(data.orgId, data.name)
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-removeDepartment', function(data)
    local source = source
    if not isAdmin(source) then return end
    OrganizationService.removeDepartment(data.deptId)
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-addRank', function(data)
    local source = source
    if not isAdmin(source) then return end
    OrganizationService.addRank(data.orgId, data.name, data.grade or 0)
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-removeRank', function(data)
    local source = source
    if not isAdmin(source) then return end
    OrganizationService.removeRank(data.rankId)
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-addContactNumber', function(data)
    local source = source
    if not isAdmin(source) then return end
    OrganizationService.addContactNumber(data.orgId, data.number, data.label)
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-removeContactNumber', function(data)
    local source = source
    if not isAdmin(source) then return end
    OrganizationService.removeContactNumber(data.contactId)
    replyWithList(source)
end)

Obelisk.onServer('admin:server:organisations-toggleContactNumber', function(data)
    local source = source
    if not isAdmin(source) then return end
    OrganizationService.toggleContactNumber(data.contactId, data.enabled)
    replyWithList(source)
end)
