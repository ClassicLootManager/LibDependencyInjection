--[[
    Loader that implements injecting LibStub dependencies
]]

LibDependencyInjection.registerGlobalPrefix('LibStub', function(retrieve, libraryName, addonName, addonTable)
    -- print(string.format("Got request for LibStub:%s from %s, resolving it synchronously", libraryName, addonName))
    if LibStub then
        return retrieve(LibStub:GetLibrary(libraryName))
    else
        -- this is for testing outside wow
        return retrieve('dummy')
    end
end)
