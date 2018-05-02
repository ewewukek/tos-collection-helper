_G['MRINDICATOR'] = _G['MRINDICATOR'] or {};
local MRINDICATOR = _G['MRINDICATOR'];

function MRINDICATOR.getItemColor(itemobj)
	--itemobj.ClassID
	return 'FFFFFF';
end

function MRINDICATOR.GET_FULL_NAME(itemobj, ...)

	local color = MRINDICATOR.getItemColor(itemobj)
	local name = _G['__GET_FULL_NAME'](itemobj, ...)

	return string.format("{#%s}{ol}%s{/}{/}", color, name);

end

local function overrideGlobal(key, value)

	keyOld = '__' .. key;
	if _G[keyOld] == nil then _G[keyOld] = _G[key] end

	_G[key] = value

end

function MRINDICATOR_ON_INIT(addon, frame)

	overrideGlobal('GET_FULL_NAME', MRINDICATOR.GET_FULL_NAME)

end
