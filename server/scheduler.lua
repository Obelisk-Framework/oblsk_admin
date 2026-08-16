-- core/plugins/oblsk_admin/server/scheduler.lua
--- oblsk_admin server: Scheduler tab NUI handlers.
local function isAdmin(player)
    local source = player:getSource()
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

--- @return table[] { action_id, label } for every ActionService-registered action
local function listAvailableActions()
    local result = {}
    for actionId, entry in pairs(ActionService.getAll()) do
        table.insert(result, { action_id = actionId, label = entry.options and entry.options.label or actionId })
    end
    table.sort(result, function(a, b) return a.action_id < b.action_id end)
    return result
end

local function replyWithList(player)
    player:emit('admin:client:scheduler-reply', {
        jobs = SchedulerService.list(),
        actions = listAvailableActions(),
    })
end

Obelisk.onClient('admin:server:scheduler-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:scheduler-create', function(player, data)
    if not isAdmin(player) then return end
    SchedulerService.create(data.actionId, data.scheduleType, {
        intervalSeconds = data.intervalSeconds,
        cronExpression = data.cronExpression,
    })
    replyWithList(player)
end)

Obelisk.onClient('admin:server:scheduler-update', function(player, data)
    if not isAdmin(player) then return end
    SchedulerService.update(data.id, data.attributes or {})
    replyWithList(player)
end)

Obelisk.onClient('admin:server:scheduler-delete', function(player, data)
    if not isAdmin(player) then return end
    SchedulerService.delete(data.id)
    replyWithList(player)
end)
