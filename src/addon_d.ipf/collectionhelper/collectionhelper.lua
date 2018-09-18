local acutil = require('acutil')

_G["COLLECTIONHELPER"] = _G["COLLECTIONHELPER"] or {}
local ch = _G["COLLECTIONHELPER"]
ch.collection_items = {}
ch.craft_items = {}

local function addRequirement (map, item_id, id, count)
    map[item_id] = map[item_id] or {}
    local id_count_list = map[item_id]

    for _, rec in ipairs(id_count_list) do
        if rec.id == id then
            rec.count = col_req.count + count
            return
        end
    end

    table.insert(id_count_list, {
        id = id,
        count = count,
    })
end

local function addCollectionRequirement (item_id, collection_id)
    addRequirement(ch.collection_items, item_id, collection_id, 1)
end

local function addCraftRequirement (item_id, count, craft_id)
    addRequirement(ch.craft_items, item_id, craft_id, count)
end

local function buildCraftRequirements (recipe, recipe_map)
    for j = 1, 5 do
        local prop_name = "Item_"..j.."_1"

        local item_id = recipe[prop_name]
        local item = GetClass("Item", item_id)
        if item == nil or item == "None" or item.NotExist == 'YES'
        or item.ItemType == 'Unused' or item.GroupName == 'Unused' then
            break
        end

        local count = GET_RECIPE_REQITEM_CNT(recipe, prop_name)
        addCraftRequirement(item_id, count, recipe.TargetItem)

        local subrecipe = recipe_map[item_id]
        if subrecipe ~= nil then
            buildCraftRequirements(subrecipe, recipe_map)
        end
    end
end

local function buildItemRequirements ()
    local recipe_map = {}

    -- "Recipe_ItemCraft" and "ItemTradeShop doesn't contain collectable item recipes
    local recipes, recipe_count = GetClassList("Recipe")
    for i = 0, recipe_count - 1 do
        local recipe = GetClassByIndexFromList(recipes, i)

        local result_item = GetClass("Item", recipe.TargetItem)
        if result_item == nil or result_item.NotExist == 'YES' or result_item.ItemType == 'Unused' then
            break
        end

        recipe_map[result_item.ClassName] = recipe
    end

    local list, size = GetClassList("Collection");
    for i = 0, size - 1 do
        local collection = GetClassByIndexFromList(list, i)

        local j = 0
        while true do
            j = j + 1

            local item_id = TryGetProp(collection, "ItemName_"..j)
            if item_id == nil or item_id == "None" then
                break
            end

            addCollectionRequirement(item_id, collection.ClassName)
        end
    end

    for _, recipe in pairs(recipe_map) do
        if ch.collection_items[recipe.TargetItem] ~= nil then
            buildCraftRequirements(recipe, recipe_map)
        end
    end
end

local function countRequiredForCollections (item_id)
    local id_count_list = ch.collection_items[item_id]
    if id_count_list == nil then
        return 0
    end

    local player_collections = session.GetMySession():GetCollection()
    local required = 0

    for _, col_req in ipairs(id_count_list) do
        local pl_col = player_collections:Get(col_req.id)
        if pl_col ~= nil then
            local col_info = geCollectionTable.Get(col_req.id)
            if pl_col:GetItemCount() < col_info:GetTotalItemCount() then
                required = required + col_info:GetNeedItemCount(item_id) - pl_col:GetItemCountByType(item_id)
            end
        else -- collection not registered yet
            required = required + col_req.count
        end
    end

    return required
end

local function countRequired (item_id)
    if ch.collection_items[item_id] == nil then
        return 0
    end

    local required = 0

    required = required + countRequiredForCollections(item_id)

    return required
end

local function GET_FULL_NAME (item, ...)
    local name = _G['GET_FULL_NAME_OLD'](item, ...)

    local required = countRequired(item.ClassName)
    if required == 0 then
        return name
    end

    local color1 = "FF40FF"
    local color2 = "FFA0FF"
    return string.format("{#%s}[ %s ]{/} {#%s}%s{/}", color1, required, color2, name)
end

function COLLECTIONHELPER_ON_INIT (addon, frame)
    buildItemRequirements()
    acutil.setupHook(GET_FULL_NAME, "GET_FULL_NAME")
    acutil.log("Collection helper loaded!")
end
