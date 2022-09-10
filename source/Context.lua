

local VERSION = 1

if LibDependencyInjection and LibDependencyInjection.version >= VERSION then
    return
end
LibDependencyInjection = {}
local lib = {
    VERSION = VERSION
}
setmetatable(LibDependencyInjection, {
    __index = lib,
    __meta = false,
    __newindex = function() error("attempt to write to read only table", 2) end
})

-- call all waiting functions
local function callWaiting(waiting, addonName)
    assert(type(waiting) == "table", "Waiting must be a table")
    local resolved = 0
    local copy = {}
    for k, v in pairs(waiting) do
        copy[k] = v
    end

    for k, callback in pairs(copy) do
        if callback[1]() then
            waiting[k] = nil
            resolved = resolved + 1
        end
    end
    return resolved
end

-- gets the given named dependencies, if it cant load all of them returns false
local function getDependencies(requiredDependencies, loadedDependencies)
    local result = {}
    for _, dependency in ipairs(requiredDependencies) do
        local resolvedDependency = loadedDependencies[dependency]
        if resolvedDependency == nil then
            -- print(string.format("failed to gET %s", dependency))
            return false
        end
        result[#result + 1] = resolvedDependency
    end
    return result
end

-- registers a function to be called with all dependencies as arguments
local function waitForDependencies(dependencies, loadedDependencies, callback)
    return function()
        local args = getDependencies(dependencies, loadedDependencies)
        if args then
            callback(unpack(args))
            return true
        end
        return false
    end
end


local function createContextTable(prefixContext, addonName)
    local r = {}

    -- a dictionary of modules that have been loaded
    local modules = {}


    -- a list of callbacks that should be called after each any new module has been resolved
    -- the function must return a boolean; when false it'll be retried later, when true it is removed from the list
    local waiting = {}
    local depth = 0
    local checkAllWaitingCallbacks = function()
        if depth ~= 0 then
            return
        end
        depth = depth + 1
        -- print("START CHECKALLWAITING")
        if (depth > 10) then
            error("Breaking, check depth > 10")
        end
        while callWaiting(waiting, addonName) > 0 do
-- print("Going another time")
        end
        -- print("END CHECKALLWAITING")
        depth = depth - 1
    end
    -- a function that returns a resolver, a resolver registers a module as loaded when called
    local createResolve = function(name)
        -- print(string.format("Creating resolver for %s", name))
        return function(module)
            if (module == nil) then
                error(string.format("Module %s MUST NOT resolve to nil", name))
            end
            if modules[name] ~= nil then
                error(string.format("Resolving already loaded module %s", name))
            end
            -- print(string.format("[[%s]] Loaded module %s, current depth: %d", addonName, name, depth))
            modules[name] = module
            return checkAllWaitingCallbacks()
        end

    end

    -- wait for a dependency, call a callback when loaded passing the dependencies as arguments
    local await = function(dependencies, callback)
        if (#dependencies == 0) then
            return callback()
        end
        -- request prefixed dependencies
        for _, dep in ipairs(dependencies) do
            local prefix, param = dep:match('(.+):(.+)')
            if prefix and prefixContext then
                -- the idea is that we wait for the prefix, as soon as it is available we request the parametrized module
                -- the parametrized module is async as well
                -- print(string.format("Adding waiter for %s because we need %s in %s", prefix, dep, addonName))

                -- a retriever is a module of type function that resolves a module based on a parameter
                prefixContext.await({prefix}, function(retriever)
                    -- if the dependency was already loaded, no need to load it again
                    if modules[dep] ~= nil then
                        return
                    end

                    local resolve = createResolve(dep)
                    -- print("retriever", param, addonName)
                    return retriever(resolve, param, addonName, r)
                end)
            end
        end
        -- print(string.format("Awaiting dependencies: %s in %s",  table.concat(dependencies, ', '), addonName))
        -- try direct load.
        local waiter = waitForDependencies(dependencies, modules, callback)
        if waiter() == false then
            waiting[#waiting + 1] = {waiter, dependencies}
        end
        -- print(string.format("Now have %d waiters and %d resolved waiters in %s", count - 1, resolved, addonName))
    end

    local defineModule = function(name, dependencies, callback)
        -- print(string.format("Defining module %s with requested dependencies: %s", name, table.concat(dependencies, ', ')))
        return await(dependencies, function(...)
            return callback(createResolve(name), ...)
        end)
    end

    local meta = {
        __meta = false,
        __index = {
            module = defineModule,
            await = await
        }
    }
    setmetatable(r, meta)
    return r



end

local prefixContext = createContextTable(nil, "[[internal]]");


function lib.registerGlobalPrefix(prefix, retriever)
    -- print(string.format("Registered global DI prefix: %s", prefix))
    prefixContext.module(prefix, {}, function(resolve)
        return resolve(retriever)
    end)
end

function lib.createContext(addonName, addonTable)
    if addonTable._diContainer == nil then
        addonTable._diContainer = createContextTable(prefixContext, addonName)
    end
    return addonTable._diContainer
end