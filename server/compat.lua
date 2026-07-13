--[[
    LS Trucking server compatibility bridge
    Inventory helper functions live here so config/config.lua only contains simple settings.
]]

Config.GetTrunkInventoryId = function(plate)
    local prefix = (Config.Inventory and Config.Inventory.TrunkPrefix) or 'trunk'
    local normalizedPlate = tostring(plate or ''):upper():gsub('%s+', '')
    return ('%s%s'):format(prefix, normalizedPlate)
end
