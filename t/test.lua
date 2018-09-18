inspect = require("inspect")
cmp_deeply = require("cmp_deeply")
require("imc_mocks")

add_object("Item", "itm_01")
add_object("Item", "itm_02")

add_collection("col_01", "itm_01", "itm_02")

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
})

print("test pass")
