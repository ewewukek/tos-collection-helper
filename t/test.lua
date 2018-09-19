inspect = require("inspect")
function dump (val) print(inspect(val)) end
cmp_deeply = require("cmp_deeply")
require("imc_mocks")

function execute_list (list)
    for _, fncall in ipairs(list) do
        local fn = table.remove(fncall, 1)
        fn(unpack(fncall))
    end
end

function test_case (args)
    imc_reset()

    io.write(args.name.."\n...")

    execute_list(args.prepare)

    dofile("../src/addon_d.ipf/collectionhelper/collectionhelper.lua")
    COLLECTIONHELPER_ON_INIT()
    ch = COLLECTIONHELPER;

xpcall(function()

    if args.expected_data ~= nil then
        local cmp = function (a, b)
            return a.id < b.id
        end

        local got = {}
        for _, property in ipairs({"collection_items", "craft_items"}) do
            args.expected_data[property] = args.expected_data[property] or {}

            local map = ch[property]
            for _, id_count_list in pairs(map) do
                table.sort(id_count_list, cmp)
            end
            got[property] = map

            map = args.expected_data[property]
            for _, id_count_list in pairs(map) do
                table.sort(id_count_list, cmp)
            end
        end

        io.write("data...")
        cmp_deeply(got, args.expected_data)
    end

    if args.count_tests ~= nil then
        io.write("counts...")
        for _, pair in ipairs(args.count_tests) do
            local item = pair[1]
            local expected = pair[2]
            local got = ch.countRequired(item, {}) -- empty inventory_counts
            if got ~= expected then
                if got == nil then got = 'nil' end
                error("wrong countRequired (no state) for "..item.."\n     got: "..got.."\nexpected: "..expected)
            end
        end
    end

    if args.player_collections ~= nil then
        for _, args in ipairs(args.player_collections) do
            add_to_player_collection(unpack(args))
        end
    end

    if args.count_tests ~= nil then
        io.write("counts with state...")
        for _, pair in ipairs(args.count_tests) do
            local item = pair[1]
            local expected = pair[3]
            local got = ch.countRequired(item, args.inventory_counts or {})
            if got ~= expected then
                if got == nil then got = 'nil' end
                error("wrong countRequired (with state) for "..item.."\n     got: "..got.."\nexpected: "..expected)
            end
        end
    end

    print("ok")

end, function (err)
    print("fail\n"..err.."\n")
end)
end

test_case {
    name = "simple collection",
    prepare = {
        {add_collection, "col", "itm"},
    },
    expected_data = {
        collection_items = {
            itm = {{
                id = "col",
                count = 1,
            }},
        },
    },
    player_collections = {
        {"col", "itm"},
    },
    inventory_counts = {
        itm = 10,
    },
    count_tests = {
        {"unknown", 0, 0},
        {"itm", 1, 0},
    },
}

test_case {
    name = "partially finished collection",
    prepare = {
        {add_collection, "col", "itm_a", "itm_b"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"col", "itm_a"},
    },
    inventory_counts = {
        itm_a = 2,
        itm_b = 3,
    },
    count_tests = {
        {"unknown", 0, 0},
        {"itm_a", 1, 0},
        {"itm_b", 1, 1},
    },
}

test_case {
    name = "two item collection",
    prepare = {
        {add_collection, "col", "itm_a", "itm_b"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"col", "itm_a", "itm_b"},
    },
    count_tests = {
        {"itm_a", 1, 0},
        {"itm_b", 1, 0},
    },
}

test_case {
    name = "repeating items",
    prepare = {
        {add_collection, "col", "itm_a", "itm_b", "itm_a", "itm_b", "itm_a"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"col", "itm_a", "itm_a", "itm_b"}
    },
    count_tests = {
        {"itm_a", 3, 1},
        {"itm_b", 2, 1},
    },
}

test_case {
    name = "item repeated in different collections",
    prepare = {
        {add_collection, "col_a", "itm_a", "itm_b"},
        {add_collection, "col_b", "itm_b", "itm_c"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"col_b", "itm_b", "itm_c"},
    },
    count_tests = {
        {"itm_a", 1, 1},
        {"itm_b", 2, 1},
        {"itm_c", 1, 0},
    },
}

test_case {
    name = "previous two combined",
    prepare = {
        {add_collection, "col_a", "itm_a", "itm_b", "itm_a", "itm_b", "itm_a"},
        {add_collection, "col_b", "itm_b", "itm_c"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"col_a", "itm_a", "itm_b", "itm_b"},
        {"col_b", "itm_b"},
    },
    count_tests = {
        {"itm_a", 3, 2},
        {"itm_b", 3, 0},
        {"itm_c", 1, 1},
    },
}

test_case {
    name = "craft in (completed) collection",
    prepare = {
        {add_recipe, "craft", {"itm", 3}},
        {add_collection, "col", "craft"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"col", "craft"},
    },
    count_tests = {
        {"craft", 1, 0},
        {"itm", 3, 0},
    }
}

test_case {
    name = "craft in collection (have in inventory)",
    prepare = {
        {add_recipe, "craft", {"itm", 3}},
        {add_collection, "col", "craft"},
    },
    inventory_counts = {
        craft = 2,
    },
    count_tests = {
        {"craft", 1, 1},
        {"itm", 3, 0},
    }
}

test_case {
    name = "craft in completed collection and inventory",
    prepare = {
        {add_recipe, "craft", {"itm", 3}},
        {add_collection, "col", "craft"},
    },
    player_collections = {
        {"col", "craft"},
    },
    inventory_counts = {
        craft = 2,
    },
    count_tests = {
        {"craft", 1, 0},
        {"itm", 3, 0},
    }
}

test_case {
    name = "nested craft in collection",
    prepare = {
        {add_recipe, "craft", {"subcraft", 2}},
        {add_recipe, "subcraft", {"itm_a", 3}, {"itm_b", 4}},
        {add_collection, "col", "craft"},
    },
    expected_data = {
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
    },
    inventory_counts = {
        subcraft = 1,
        itm_a = 10,
    },
    count_tests = {
        {"craft", 1, 1},
        {"subcraft", 2, 2},
        {"itm_a", 6, 3},
        {"itm_b", 8, 4},
    },
}

test_case {
    name = "item in two collection crafts",
    prepare = {
        {add_recipe, "craft_1", {"itm_a", 1}, {"itm_b", 2}},
        {add_recipe, "craft_2", {"itm_a", 3}, {"itm_c", 4}},
        {add_collection, "crafts", "craft_1", "craft_2"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"crafts", "craft_1"},
    },
    inventory_counts = {
        craft_2 = 1,
    },
    count_tests = {
        {"craft_1", 1, 0},
        {"craft_2", 1, 1},
        {"itm_a", 4, 0},
        {"itm_b", 2, 0},
        {"itm_c", 4, 0},
    },
}

test_case {
    name = "same crafts in collection (partially completed)",
    prepare = {
        {add_recipe, "craft", {"itm", 1}},
        {add_collection, "col", "craft", "craft"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"col", "craft"},
    },
    count_tests = {
        {"craft", 2, 1},
        {"itm", 2, 1},
    },
}

test_case {
    name = "same crafts in collection (one in inventory)",
    prepare = {
        {add_recipe, "craft", {"itm", 1}},
        {add_collection, "col", "craft", "craft"},
    },
    inventory_counts = {
        craft = 1,
    },
    count_tests = {
        {"craft", 2, 2},
        {"itm", 2, 1},
    },
}

test_case {
    name = "craft and subcraft in collection",
    prepare = {
        {add_recipe, "craft", {"subcraft", 2}},
        {add_recipe, "subcraft", {"itm", 3}},
        {add_collection, "col", "craft"},
        {add_collection, "subcol", "subcraft"},
    },
    expected_data = {
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
    },
    player_collections = {
        {"subcol", "subcraft"},
    },
    inventory_counts = {
        subcraft = 1,
    },
    count_tests = {
        {"craft", 1, 1},
        {"subcraft", 3, 2},
        {"itm", 9, 3},
    },
}

test_case {
    name = "craft and subcraft in collection + craft with shared item requirements",
    prepare = {
        {add_recipe, "craft_1", {"subcraft_1", 1}},
        {add_recipe, "subcraft_1", {"itm", 3}},
        {add_recipe, "craft_2", {"itm", 5}},
        {add_collection, "col_1", "craft_1"},
        {add_collection, "subcol_1", "subcraft_1"},
        {add_collection, "col_2", "craft_2"},
    },
    expected_data = {
        collection_items = {
            craft_1 = {{
                id = "col_1",
                count = 1,
            }},
            subcraft_1 = {{
                id = "subcol_1",
                count = 1,
            }},
            craft_2 = {{
                id = "col_2",
                count = 1,
            }},
        },
        craft_items = {
            subcraft_1 = {{
                id = "craft_1",
                count = 1,
            }},
            itm = {{
                id = "subcraft_1",
                count = 3,
            }, {
                id = "craft_2",
                count = 5,
            }},
        },
    },
    player_collections = {
        {"subcol_1", "subcraft_1"},
    },
    count_tests = {
        {"craft_1", 1, 1},
        {"subcraft_1", 2, 1},
        {"craft_2", 1, 1},
        {"itm", 11, 8},
    },
}

print("all tests passed")
