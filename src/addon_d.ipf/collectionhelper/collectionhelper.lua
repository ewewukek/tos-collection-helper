local acutil = require('acutil')

_G['COLLECTIONHELPER'] = _G['COLLECTIONHELPER'] or {}
local COLLECTIONHELPER = _G['COLLECTIONHELPER']

function COLLECTIONHELPER.getItemColor(itemobj)
    --itemobj.ClassID
    return 'FFFF00'
end

function COLLECTIONHELPER.GET_FULL_NAME(itemobj, ...)

    local color = COLLECTIONHELPER.getItemColor(itemobj)
    local name = _G['__GET_FULL_NAME'](itemobj, ...)

    return string.format("{#%s}{ol}%s{/}{/}", color, name)

end

function COLLECTIONHELPER_ON_INIT(addon, frame)

    acutil.setupHook(COLLECTIONHELPER.GET_FULL_NAME, "GET_FULL_NAME")
    acutil.log("Collection helper loaded!")

end
