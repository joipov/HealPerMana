---@meta

--- Blizzard globals used by Heal Per Mana that the Ketho Core annotations may
--- omit (Forever secret-value helpers, sound kit, and the optional `_G` frames
--- read at runtime).

---@type fun(value: any): boolean
issecretvalue = issecretvalue

---@type fun(value: any): boolean
canaccessvalue = canaccessvalue

---@type fun(value: any): boolean
issecrettable = issecrettable

---@type fun(value: any): boolean
canaccesstable = canaccesstable

---@type table
SOUNDKIT = SOUNDKIT

---@type fun(kit: any)
PlaySound = PlaySound

-- Optional Blizzard frames are read through `_G.<name>`. LuaLS has the Lua
-- builtins disabled, so `_G` has no index type and every such lookup is an
-- "undefined-field". Type `_G` here so those lookups resolve.
---@type table<string, any>
_G = _G
