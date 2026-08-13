AdminConfig = {}

--- Default key that opens/closes the staff panel. Players can't currently
--- override this (no per-plugin entry in oblsk_keybinds' resolver chain
--- yet) — editing this file is the only way to change it, matching how
--- every other plugin ships an unconfigurable default_key today.
AdminConfig.keybind = 'F6'

return AdminConfig
