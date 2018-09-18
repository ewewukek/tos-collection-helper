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

return acutil;
