--[[
    Loader that implements waiting for an event as a dependency.
    This will wait for an event to happen once and then resolve with the data from the event.
    Only the first time it fires is considered.
]]
local frame = CreateFrame("Frame");

-- register for some events that fire very early
for _, v in pairs({
    "ADDON_LOADED"
}) do
    frame:RegisterEvent(v)

end

local eventCache = {}
local resolvers = {}
frame:SetScript("OnEvent", function(self, event, ...)
    -- print(string.format("Received %s with data:", event))
    -- for k, v in pairs({...}) do

    --     print(k, v)
    -- end
    if eventCache[event] == nil then
        -- print("Adding to event cache:", event)
        frame:UnregisterEvent(event)
        local args = {...}
        if #args == 0 then
            args = {"no args"}
        end
        eventCache[event] = args

        local eventResolvers = resolvers[event] or {}
        resolvers[event] = {}
        for _, resolve in pairs(eventResolvers) do
            resolve(unpack(args))
        end
    end
end)

LibDependencyInjection.registerGlobalPrefix('FirstEvent', function(resolve, eventName, addonName, addonTable)

    -- event might have been triggered in the past
    if (eventCache[eventName] ~= nil) then
        print(string.format("Got request for FirstEvent:%s, resolving it synchronously", eventName))
        resolve(unpack(eventCache[eventName]))
    else
        print(string.format("Got request for FirstEvent:%s, resolving it ASYNC", eventName))
        frame:RegisterEvent(eventName)
        -- register for the event
        if (resolvers[eventName] == nil) then
            resolvers[eventName] = {}
        end
        resolvers[eventName][#resolvers[eventName]+1] = resolve
    end

end)
