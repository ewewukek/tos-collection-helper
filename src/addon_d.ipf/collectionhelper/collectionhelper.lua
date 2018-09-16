local acutil = require('acutil')

_G['COLLECTIONHELPER'] = _G['COLLECTIONHELPER'] or {}
local ch = _G['COLLECTIONHELPER']

local function getItemColor(itemobj)
    --itemobj.ClassID
    return 'FFFF00'
end

local function GET_FULL_NAME(itemobj, ...)
    local color = getItemColor(itemobj)
    local name = _G['GET_FULL_NAME_OLD'](itemobj, ...)

    return string.format("{#%s}{ol}%s{/}{/}", color, name)
end

function COLLECTIONHELPER_ON_INIT(addon, frame)
    acutil.setupHook(GET_FULL_NAME, "GET_FULL_NAME")
    acutil.log("Collection helper loaded!")
end
