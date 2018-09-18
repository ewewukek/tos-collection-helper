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

    local cmp = function (a, b)
        return a.id < b.id
    end

    for _, property in ipairs({"collection_items", "craft_items"}) do
        if expected_data[property] ~= nil then
            io.write(property.."...")

            local got = ch[property]
            for _, id_count_list in pairs(got) do
                table.sort(id_count_list, cmp)
            end

            xpcall(function () cmp_deeply(got, expected_data[property]) end, function (err)
                print("fail\n"..err)
            end)
        end
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

test_case(
"two item collection", {
    {add_collection, "col", "itm_a", "itm_b"},
}, {
    collection_items = {
        itm_a = {{
            id = "col",
            count = 1,
        }},
        itm_b = {{
            id = "col",
            count = 1,
        }},
    },
})

test_case(
"repeating items", {
    {add_collection, "col", "itm_a", "itm_b", "itm_a", "itm_b", "itm_a"},
}, {
    collection_items = {
        itm_a = {{
            id = "col",
            count = 3,
        }},
        itm_b = {{
            id = "col",
            count = 2,
        }},
    },
})

test_case(
"item repeated in different collections", {
    {add_collection, "col_a", "itm_a", "itm_b"},
    {add_collection, "col_b", "itm_b", "itm_c"},
}, {
    collection_items = {
        itm_a = {{
            id = "col_a",
            count = 1,
        }},
        itm_b = {{
            id = "col_a",
            count = 1,
        }, {
            id = "col_b",
            count = 1,
        }},
        itm_c = {{
            id = "col_b",
            count = 1,
        }},
    },
})

test_case(
"previous two combined", {
    {add_collection, "col_a", "itm_a", "itm_b", "itm_a", "itm_b", "itm_a"},
    {add_collection, "col_b", "itm_b", "itm_c"},
}, {
    collection_items = {
        itm_a = {{
            id = "col_a",
            count = 3,
        }},
        itm_b = {{
            id = "col_a",
            count = 2,
        }, {
            id = "col_b",
            count = 1,
        }},
        itm_c = {{
            id = "col_b",
            count = 1,
        }},
    },
})

test_case(
"craft in collection", {
    {add_recipe, "craft", "itm", 3},
    {add_collection, "col", "craft"},
}, {
    collection_items = {
        craft = {{
            id = "col",
            count = 1,
        }},
    },
    craft_items = {
        itm = {{
            id = "craft",
            count = 3,
        }},
    },
})

test_case(
"nested craft in collection", {
    {add_recipe, "craft", "subcraft", 2},
    {add_recipe, "subcraft", "itm_a", 3, "itm_b", 4},
    {add_collection, "col", "craft"},
}, {
    collection_items = {
        craft = {{
            id = "col",
            count = 1,
        }},
    },
    craft_items = {
        subcraft = {{
            id = "craft",
            count = 2,
        }},
        itm_a = {{
            id = "subcraft",
            count = 3,
        }},
        itm_b = {{
            id = "subcraft",
            count = 4,
        }},
    },
})

test_case(
"item in two collection crafts", {
    {add_recipe, "craft_1", "itm_a", 1, "itm_b", 2},
    {add_recipe, "craft_2", "itm_a", 3, "itm_c", 4},
    {add_collection, "crafts", "craft_1", "craft_2"},
}, {
    collection_items = {
        craft_1 = {{
            id = "crafts",
            count = 1,
        }},
        craft_2 = {{
            id = "crafts",
            count = 1,
        }},
    },
    craft_items = {
        itm_a = {{
            id = "craft_1",
            count = 1,
        }, {
            id = "craft_2",
            count = 3,
        }},
        itm_b = {{
            id = "craft_1",
            count = 2,
        }},
        itm_c = {{
            id = "craft_2",
            count = 4,
        }},
    },
})

test_case(
"same crafts in collection", {
    {add_recipe, "craft", "itm", 1},
    {add_collection, "col", "craft", "craft"},
}, {
    collection_items = {
        craft = {{
            id = "col",
            count = 2,
        }},
    },
    craft_items = {
        itm = {{
            id = "craft",
            count = 1,
        }},
    },
})

test_case(
"craft and subcraft in collection", {
    {add_recipe, "craft", "subcraft", 2},
    {add_recipe, "subcraft", "itm", 3},
    {add_collection, "col", "craft"},
    {add_collection, "subcol", "subcraft"},
}, {
    collection_items = {
        craft = {{
            id = "col",
            count = 1,
        }},
        subcraft = {{
            id = "subcol",
            count = 1,
        }},
    },
    craft_items = {
        subcraft = {{
            id = "craft",
            count = 2,
        }},
        itm = {{
            id = "subcraft",
            count = 3,
        }},
    },
})

print("all tests passed")
