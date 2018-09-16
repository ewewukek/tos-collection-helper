_G['COLLECTIONHELPER'] = _G['COLLECTIONHELPER'] or {};
local COLLECTIONHELPER = _G['COLLECTIONHELPER'];

function COLLECTIONHELPER.getItemColor(itemobj)
	--itemobj.ClassID
	return 'FFFFFF';
end

function COLLECTIONHELPER.GET_FULL_NAME(itemobj, ...)

	local color = COLLECTIONHELPER.getItemColor(itemobj)
	local name = _G['__GET_FULL_NAME'](itemobj, ...)

	return string.format("{#%s}{ol}%s{/}{/}", color, name);

end

local function overrideGlobal(key, value)

	keyOld = '__' .. key;
	if _G[keyOld] == nil then _G[keyOld] = _G[key] end

	_G[key] = value

end

function COLLECTIONHELPER_ON_INIT(addon, frame)

	overrideGlobal('GET_FULL_NAME', COLLECTIONHELPER.GET_FULL_NAME)

end
