-- core/plugins/oblsk_admin/server/jobs.lua
--- oblsk_admin server: Jobs tab NUI handlers.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

local function replyWithList(player)
    player:emit('admin:client:jobs-reply', { jobs = Jobs.admin.listJobs() })
end

local function replyWithDetail(player, jobId)
    player:emit('admin:client:jobs-detail-reply', {
        jobId = jobId,
        levels = Jobs.admin.listLevels(jobId),
        tasks = Jobs.admin.listTasks(jobId),
        routes = Jobs.admin.listRoutes(jobId),
    })
end

Obelisk.onClient('admin:server:jobs-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:jobs-detail', function(player, data)
    if not isAdmin(player) then return end
    replyWithDetail(player, data.jobId)
end)

Obelisk.onClient('admin:server:jobs-create', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.createJob(data.attributes or {})
    replyWithList(player)
end)

Obelisk.onClient('admin:server:jobs-update', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.updateJob(data.jobId, data.attributes or {})
    replyWithList(player)
end)

Obelisk.onClient('admin:server:jobs-delete', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.deleteJob(data.jobId)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:jobs-upsert-level', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.upsertLevel(data.jobId, data.level, data.xpRequired, data.label)
    replyWithDetail(player, data.jobId)
end)

Obelisk.onClient('admin:server:jobs-delete-level', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.deleteLevel(data.levelId)
    replyWithDetail(player, data.jobId)
end)

Obelisk.onClient('admin:server:jobs-upsert-task', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.upsertTask(data.jobId, data.taskKey, data.payAmount, data.xpAmount)
    replyWithDetail(player, data.jobId)
end)

Obelisk.onClient('admin:server:jobs-delete-task', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.deleteTask(data.taskId)
    replyWithDetail(player, data.jobId)
end)

Obelisk.onClient('admin:server:jobs-upsert-route', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.upsertRoute(data.jobId, data.name, data.minLevel, data.stops or {})
    replyWithDetail(player, data.jobId)
end)

Obelisk.onClient('admin:server:jobs-delete-route', function(player, data)
    if not isAdmin(player) then return end
    Jobs.admin.deleteRoute(data.routeId)
    replyWithDetail(player, data.jobId)
end)
