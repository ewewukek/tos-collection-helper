inspect = require("inspect")
function dump (val) print(inspect(val)) end
cmp_deeply = require("cmp_deeply")
require("imc_mocks")

function test_case (name, prepare, expected_data)
    reset_classes()

    io.write(name.."...")

    for _, fncall in ipairs(prepare) do
        local fn = table.remove(fncall, 1)
        fn(unpack(fncall))
    end

    dofile("../src/addon_d.ipf/collectionhelper/collectionhelper.lua")
    COLLECTIONHELPER_ON_INIT()
    ch = COLLECTIONHELPER;

    for property, value in pairs(expected_data) do
        cmp_deeply(ch[property], value)
    end

    print("ok")
end

test_case(
    "single item collection", {
    {add_collection, "col", "itm"},
}, {
    collection_items = {
        itm = {{
            id = "col",
            count = 1,
        }},
    },
})

print("all tests passed")
