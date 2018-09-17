local inspect = require("inspect")

-- simple straightforward deep table comparsion
local function cmp (path, got, expected)
    local tg = type(got)
    local te = type(expected)
    if type(got) == "table" and type(expected) == "table" then
        for k, _ in ipairs(expected) do
            cmp(path..'['..inspect(k)..']', got[k], expected[k])
        end
        for k, _ in ipairs(got) do
            cmp(path..'['..inspect(k)..']', got[k], expected[k])
        end
        for k, _ in pairs(expected) do
            cmp(path..'['..inspect(k)..']', got[k], expected[k])
        end
        for k, _ in pairs(got) do
            cmp(path..'['..inspect(k)..']', got[k], expected[k])
        end
        return
    end
    if got ~= expected then
        error("Structures begin differing at:"
            .."\n     got"..path.." = "..inspect(got)
            .."\nexpected"..path.." = "..inspect(expected)
        )
    end
end

return function (a, b)
    return cmp("", a, b)
end
