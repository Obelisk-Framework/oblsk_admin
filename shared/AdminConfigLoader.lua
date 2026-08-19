--- AdminConfigLoader.lua - loads AdminConfig.lua if a server owner has created one
--- (gitignored, so their edits survive a git pull), falling back to the
--- tracked AdminConfig.lua.example defaults otherwise.
if AdminConfig then
    return
end

if not LoadConfigFile('plugins/oblsk_admin/shared/AdminConfig.lua') then
    LoadConfigFile('plugins/oblsk_admin/shared/AdminConfig.lua.example')
end
