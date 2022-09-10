--[[
    Loader that implements injecting LibStub dependencies
]]

LibDependencyInjection.registerGlobalPrefix('LibStub', function(retrieve, libraryName, addonName)
    -- print(string.format("Got request for LibStub:%s from %s, resolving it synchronously", libraryName, addonName))
    if LibStub then
        return retrieve(LibStub:GetLibrary(param))
    else
        -- this is for testing outside wow
        return retrieve('dummy')
    end
end)
