inspect = require("inspect")
function dump (val) print(inspect(val)) end
cmp_deeply = require("cmp_deeply")
require("imc_mocks")

add_collection("col_01", "itm_01", "itm_02")

add_recipe("craft_01", "itm_01", 10)
add_collection("col_02", "craft_01")

dofile("../src/addon_d.ipf/collectionhelper/collectionhelper.lua")
COLLECTIONHELPER_ON_INIT()
local ch = COLLECTIONHELPER;

cmp_deeply(ch.collection_items, {
    itm_01 = {{
        id = "col_01",
        count = 1,
    }},
    itm_02 = {{
        id = "col_01",
        count = 1,
    }},
    craft_01 = {{
        id = "col_02",
        count = 1,
    }},
})

cmp_deeply(ch.craft_items, {
    itm_01 = {{
        id = "craft_01",
        count = 10,
    }},
})

print("test pass")
