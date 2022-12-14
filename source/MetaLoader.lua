--[[
    Loader that implements waiting for specific events implemented by this library
]]
local frame = CreateFrame("Frame");

local loadedAddons = {}

local addonLoadedResolvers = {}

frame:SetScript("OnEvent", function(self, event, arg1)
    if (event == "ADDON_LOADED") then
        loadedAddons[arg1] = true
        for k, v in pairs(addonLoadedResolvers) do
            print(k, #v)
        end
        local resolvers = addonLoadedResolvers[arg1] or {}
        addonLoadedResolvers[arg1] = nil
        for _, resolve in pairs(resolvers) do
            resolve(true)
        end
    end
end)

LibDependencyInjection.registerGlobalPrefix('Meta', function(resolve, name, addonName, addonTable)
    if (name == 'ADDON_LOADED') then
        -- check already loaded
        if loadedAddons[addonName] ~= nil then
            return resolve(true)
        end
        if (addonLoadedResolvers[addonName] == nil) then
            addonLoadedResolvers[addonName] = {resolve}
        else
            table.insert(addonLoadedResolvers[addonName], resolve)
        end
        return frame:RegisterEvent('ADDON_LOADED')
    elseif name == "ADDON_TABLE" then
        return resolve(addonTable)
    end
    error(string.format("Unknown meta event: %s", name))

end)
