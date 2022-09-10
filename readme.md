# Dependency injection for WoW addons

Historically dependency loading in WoW addons is solved in multiple ways:
- controlling the file loading order
- everyone including every library (since that's the only way they can be sure dependencies load before code that requires them)
- using LibStub as a service locator

# Dependency injection

Using dependency injection means telling someone, in this case LibDI, what you need. That's all.
Added benefit of this approach is that you'll automatically get local references which may speed up your code by irrelevant amounts unless you're executing very tight loops in your main addon code.

## Definition of a depency

In this readme a dependency is anything your addon requires before initializing itself. Your addon can (and probably should) be modular, so each part of your addon may depend on both external and internal dependencies. Environmental dependencies are supported as well.

# Syntax

When defining a module you'll have 2 lines of boilerplate, regardless of the number of dependencies.
Below is an exampe, the first 2 lines of code are the boilerplate (and the last one as well if you want to be precise)
```lua
-- we use this to create a DI container just for your addon
-- you may use this in any file, you'll always get the same DI container
local define = createContext(...)

-- you declare your modules like this:
define.module("module name", {"list", "of", "dependencies"}, function(resolve, list, of, dependencies)
    -- this function is called when all its dependencies are available, these dependencies are passed as parameters so you have them immediately available as local variable!

    -- your module is define when you call the first parameter with your module as an argument. Your module should probably be a table, but any non-nil value is allowed
    local myModule = {}
    function myModule:Add(a, b)
        return a + b
    end

    -- call resolve when your module is initialized. You do not have to do this immediately, you could wait for events or put a delay on it if you want to.
    C_Timer.After(15, function()
    resolve(myModule)
    end)

    -- the return value of this function is ignored
end)


```

## Code samples

```lua

-- we'll use the addonName in case we need it, we'll also store the DI container in your addon's table under the key _diContainer
local define = createContext(...)

define.module("ModuleC", {"ModuleA", "ModuleB"}, function(resolve, a, b)
    -- initialize module C here

    local module = a + b



    -- resolve module
    resolve(module)

end)
```

## Prefixes

We support special prefixes to allow loading common types of dependencies. A prefix dependency is a dependency with 1 string parameter, it is define like this: `PREFIX:PARAM`.

### LibStub

Your code can require libraries registered via LibStub:
```lua
local define = createContext(...)

define.module("ModuleC", {"ModuleA", "ModuleB", "LibStub:LibSerialize1.0"}, function(resolve, a, b, libSerialize)
    -- initialize module C here

    local module = a + b



    -- resolve module
    resolve(module)

end)

```

### SavedVariable

Your code might need access to some saved variables; we'll wait for them to be loaded before launching your code.
- This'll only work for saved variables that belong to your addon for now
- This will initialize `nil` values to an empty table, your saved variable(s) should be tables

```lua
local define = createContext(...)

define.module("ModuleC", {"ModuleA", "ModuleB", "SavedVariable:LIB_DI_SAVED_VAR"}, function(resolve, a, b, savedVariable)
    -- initialize module C here

    local module = a + b



    -- resolve module
    resolve(module)

end)

```

### FirstEvent

Sometimes your addon might depend on an event before it can be loaded. For example an addon could require data only available after PLAYER_ENTERING_WORLD.
The FirstEvent prefix allows you to wait for these events.

```lua
local define = createContext(...)

define.module("ModuleC", {"ModuleA", "ModuleB", "FirstEvent:PLAYER_ENTERING_WORLD"}, function(resolve, a, b, savedVariable)
    -- initialize module C here

    local module = a + b



    -- resolve module
    resolve(module)

end)
```
### Meta

The Meta prefix allows us to add our own abstract events that may be derived from any combination of in game events or library data.
Supported parameters are listed here:

#### ADDON_LOADED

 ```lua
local define = createContext(...)

define.module("ModuleC", {"ModuleA", "ModuleB", "Meta:ADDON_LOADED"}, function(resolve, a, b, _)

    -- this is only ran after THIS addon was loaded, this means all lua was parsed and your saved variables are available

    local module = a + b



    -- resolve module
    resolve(module)

end)
```

Internally our `SavedVariable` prefix uses this meta event to know when it is okay to try and read the variable.
