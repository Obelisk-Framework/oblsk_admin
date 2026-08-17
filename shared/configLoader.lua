--- configLoader - loads config.lua if a server owner has created one
--- (gitignored, so their edits survive a git pull), falling back to the
--- tracked config.lua.example defaults otherwise.
if AdminConfig then
    return
end

local resourceName = GetCurrentResourceName()

local function loadConfigFile(path)
    local content = LoadResourceFile(resourceName, path)
    if not content then
        return false
    end
    local chunk = load(content, '@' .. path)
    if not chunk then
        return false
    end
    chunk()
    return true
end

if not loadConfigFile('plugins/oblsk_admin/shared/config.lua') then
    loadConfigFile('plugins/oblsk_admin/shared/config.lua.example')
end
