


function runDemo()
    local define = LibDependencyInjection.createContext("LibDependencyInjection", {})




    -- define.prefix('Event', {}, function(resolve, a)


    -- end)



    -- ModuleC.lua
    define.module("ModuleC", {"ModuleA", "ModuleB", "LibStub:Test"}, function(resolve, a, b, t)
       -- initialize module C here

       local module = a + b
       print(string.format("init C with value %d, got test from libstub: %s", module, t))
       resolve(module)

    end)

    -- ModuleB.lua
    define.module("ModuleB", {"ModuleA", "FirstEvent:PLAYER_ENTERING_WORLD", "SavedVariable:LIB_DI_SAVED_VAR"}, function(resolve, a, _, savedVariable)
        -- initialize module B here
        print(string.format("Initializing module B, the value type of the saved variable is %s, its counter is %d", type(savedVariable), savedVariable.counter))
        if savedVariable.counter == nil then
            savedVariable.counter = 1
        else
            savedVariable.counter = savedVariable.counter + 1
        end
        local module = a + 15
        resolve(module)

     end)

    local f
    define.module("ModuleA", {}, function(resolve)
        print("init a")
        f = resolve
     end)

     -- fake async by calling the resolve outside the require
     f(7)

end

runDemo()