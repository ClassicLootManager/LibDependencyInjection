--[[
    Loader that implements waiting for saved variables
]]
LibDependencyInjection.registerGlobalPrefix('SavedVariable', function(resolve, variableName, addonName, addonTable)


    print(string.format("Got request for saved var %s from %s", variableName, addonName))
    -- We should wait for our addon to be loaded.
    addonTable._diContainer.await({"Meta:ADDON_LOADED"}, function()
        print(string.format("Getting saved var %s", variableName));
        -- after the addon is loaded we resolve the variable.
        _G[variableName] = _G[variableName] or {}
        resolve(_G[variableName])
    end)
end)
