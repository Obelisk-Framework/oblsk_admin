--- Toggle Admin Panel Action - opens/closes the staff panel.
--- Gated by the shared `isAdmin` policy (core/server/Policies/IsAdminPolicy.lua)
--- via PolicyService — ActionService.execute already runs every policy
--- attached to an action before its handler fires, so this action's handler
--- itself doesn't need its own permission check. See server/main.lua's boot
--- thread for where the policy actually gets attached.
ActionService.register('admin:server:toggle-panel', function(player, data)
    player:emit('admin:client:toggle-panel')
end, { label = 'Toggle admin panel', default_key = AdminConfig.keybind })
