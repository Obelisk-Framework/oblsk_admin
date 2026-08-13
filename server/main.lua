--- oblsk_admin server: panel open/close gate. Every other server file in
--- this plugin (organisations handlers, Task 7) redefines the same
--- isAdmin(source) guard locally — this codebase has no shared helper
--- module for it (see OrganizationCommands.lua/AccountCommands.lua for the
--- existing precedent). options.policies on ActionService.register is not
--- wired to anything today, so this guard is the real security boundary,
--- not a UX nicety layered on top of it.
local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, 'admin')
end

ActionService.register('admin:toggle-panel', function(source, data)
    if not isAdmin(source) then return end
    Obelisk.emitClient(source, 'admin:client:toggle-panel')
end, { label = 'Toggle admin panel', default_key = Config.keybind })
