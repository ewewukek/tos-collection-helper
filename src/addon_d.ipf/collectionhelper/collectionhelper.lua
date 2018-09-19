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
            rec.count = rec.count + count
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
    recipe_map[recipe.TargetItem] = nil -- prevent processing same recipe twice
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

    local item = GetClass("Item", item_id)

    for _, col_req in ipairs(id_count_list) do
        local collection = GetClass("Collection", col_req.id)
        local pl_col = player_collections:Get(collection.ClassID)
        if pl_col ~= nil then
            local col_info = geCollectionTable.Get(collection.ClassID)
            if pl_col:GetItemCount() < col_info:GetTotalItemCount() then
                required = required + col_info:GetNeedItemCount(item.ClassID) - pl_col:GetItemCountByType(item.ClassID)
            end
        else -- collection not registered yet
            required = required + col_req.count
        end
    end

    return required
end

local function fillInventoryCounts ()
    local inventory_counts = {}
    local list = session.GetInvItemList()

    local index = list:Head()
    while true do
        if index == list:InvalidIndex() then
            break
        end

        local slot = list:Element(index)
        local item = GetIES(slot:GetObject())
        local item_id = item.ClassName
        inventory_counts[item_id] = (inventory_counts[item_id] or 0) + slot.count
        index = list:Next(index)
    end

    return inventory_counts
end

local function countRequiredForCrafts (item_id, inventory_counts)
    local id_count_list = ch.craft_items[item_id]
    if id_count_list == nil then
        return 0
    end

    local required = 0

    for _, rec in ipairs(id_count_list) do
        local item_id = rec.id
        local item_required = ch.countRequired(item_id, inventory_counts)
        item_required = item_required - (inventory_counts[item_id] or 0)
        if item_required > 0 then
            required = required + (rec.count * item_required)
        end
    end

    return required
end

function ch.countRequired (item_id, inventory_counts)
    local required = 0

    required = required + countRequiredForCollections(item_id)
    required = required + countRequiredForCrafts(item_id, inventory_counts)

    return required
end

local function GET_FULL_NAME (item, ...)
    local name = _G['GET_FULL_NAME_OLD'](item, ...)

    if ch.collection_items[item.ClassName] == nil and ch.craft_items[item.ClassName] == nil then
        return name
    end

    local inventory_counts = fillInventoryCounts()
    local required = ch.countRequired(item.ClassName, inventory_counts)

    local have = inventory_counts[item.ClassName] or 0
    if have > required then have = required end

    local color = "800080"
    if required == 0 then
        return string.format("{#%s}[{/}0{#%s}]{/} %s", color, color, name)
    end
    return string.format("{#%s}[{/}%s{#%s}/{/}%s{#%s}]{/} %s", color, have, color, required, color, name)
end

function COLLECTIONHELPER_ON_INIT (addon, frame)
    buildItemRequirements()
    acutil.setupHook(GET_FULL_NAME, "GET_FULL_NAME")
    acutil.log("Collection helper loaded!")
end
