-- minimal api-compliant subset of TOS Community AC-Util

local acutil = {};

function acutil.setupHook (newFunction, hookedFunctionStr)
    local storeOldFunc = hookedFunctionStr.."_OLD"
    if _G[storeOldFunc] == nil then
        _G[storeOldFunc] = _G[hookedFunctionStr]
    end
    _G[hookedFunctionStr] = newFunction
end

function acutil.log (msg)
end

function acutil.loadJSON (path, dest)
    return nil, "file not found"
end

function acutil.saveJSON (path, data)
end

return acutil;
