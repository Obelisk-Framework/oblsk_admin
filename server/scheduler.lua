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

--- @param scheduleType string 'interval' | 'cron'
--- @param intervalSeconds number|nil
--- @param cronExpression string|nil
--- @return boolean ok
--- @return string|nil reason
local function validateSchedule(scheduleType, intervalSeconds, cronExpression)
    if scheduleType == 'interval' then
        if type(intervalSeconds) ~= 'number' or intervalSeconds <= 0 then
            return false, 'Interval must be a positive number of seconds'
        end
        return true
    elseif scheduleType == 'cron' then
        local ok = pcall(CronExpression.matches, cronExpression, os.time())
        if not ok then
            return false, 'Invalid cron expression'
        end
        return true
    end
    return false, 'Unknown schedule type'
end

local UPDATABLE_FIELDS = { 'action_id', 'schedule_type', 'interval_seconds', 'cron_expression', 'enabled' }

--- @param attrs table raw attributes from the client
--- @return table filtered to only known, updatable columns
local function filterUpdatableAttrs(attrs)
    local filtered = {}
    for _, field in ipairs(UPDATABLE_FIELDS) do
        if attrs[field] ~= nil then
            filtered[field] = attrs[field]
        end
    end
    return filtered
end

Obelisk.onClient('admin:server:scheduler-list', function(player)
    if not isAdmin(player) then return end
    replyWithList(player)
end)

Obelisk.onClient('admin:server:scheduler-create', function(player, data)
    if not isAdmin(player) then return end
    local ok, reason = validateSchedule(data.scheduleType, data.intervalSeconds, data.cronExpression)
    if not ok then
        NotificationService.error(player, 'Scheduler', reason)
        return
    end
    SchedulerService.create(data.actionId, data.scheduleType, {
        intervalSeconds = data.intervalSeconds,
        cronExpression = data.cronExpression,
    })
    replyWithList(player)
end)

Obelisk.onClient('admin:server:scheduler-update', function(player, data)
    if not isAdmin(player) then return end
    local attrs = filterUpdatableAttrs(data.attributes or {})
    if attrs.schedule_type or attrs.interval_seconds ~= nil or attrs.cron_expression ~= nil then
        local ok, reason = validateSchedule(
            attrs.schedule_type or data.currentScheduleType,
            attrs.interval_seconds,
            attrs.cron_expression
        )
        if not ok then
            NotificationService.error(player, 'Scheduler', reason)
            return
        end
    end
    SchedulerService.update(data.id, attrs)
    replyWithList(player)
end)

Obelisk.onClient('admin:server:scheduler-delete', function(player, data)
    if not isAdmin(player) then return end
    SchedulerService.delete(data.id)
    replyWithList(player)
end)
