local acutil = require('acutil')

_G["COLLECTIONHELPER"] = _G["COLLECTIONHELPER"] or {}
local ch = _G["COLLECTIONHELPER"]
local loaded = false
ch.collection_items = {}
ch.craft_items = {}

local config = { -- default configuration
    show_no_longer_required_items = true,
    no_longer_required_tpl        = "{@st66b}{s20}({#00A000}0{/}){/}{/} %s",
    have_lt_required_tpl          = "{@st66b}{s20}({#FFFF00}%s{/}/{#FFFF00}%s{/}){/}{/} %s",
    have_ge_required_tpl          = "{@st66b}{s20}({#00FF00}%s{/}){/}{/}{/} %s",
    version                       = 1,
}

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
    local dropped_recipes = {
        BRC01_134 = true,
        BRC01_136 = true,
        BRC01_139 = true,
        BRC02_106 = true,
        BRC02_111 = true,
        CAN01_109 = true,
        NECK01_131 = true,
        NECK01_139 = true,
        NECK01_141 = true,
        NECK01_142 = true,
        NECK01_143 = true,
        NECK02_106 = true,
        NECK02_108 = true,
        NECK02_109 = true,
        SPR01_104 = true,
        STF01_109 = true,
        TBW01_109 = true,
    }

    -- "Recipe_ItemCraft" and "ItemTradeShop doesn't contain collectable item recipes
    local recipes, recipe_count = GetClassList("Recipe")
    for i = 0, recipe_count - 1 do
        local recipe = GetClassByIndexFromList(recipes, i)

        local result_item = GetClass("Item", recipe.TargetItem)
        if result_item ~= nil and result_item.NotExist ~= 'YES' and result_item.ItemType ~= 'Unused'
        and dropped_recipes[result_item.ClassName] then
            recipe_map[result_item.ClassName] = recipe
        end
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

    FOR_EACH_INVENTORY(list, function(list, slot)
        local item = GetIES(slot:GetObject())
        local item_id = item.ClassName
        inventory_counts[item_id] = (inventory_counts[item_id] or 0) + slot.count
    end, false)

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

local function LINK_ITEM_TEXT (...)
    ch.inside_link_item_text = true
    local ret = _G['LINK_ITEM_TEXT_OLD'](...)
    ch.inside_link_item_text = false
    return ret
end

local function GET_FULL_NAME (item, ...)
    local name = _G['GET_FULL_NAME_OLD'](item, ...)

    if ch.inside_link_item_text then
        return name
    end

    if ch.collection_items[item.ClassName] == nil and ch.craft_items[item.ClassName] == nil then
        return name
    end

    local inventory_counts = fillInventoryCounts()
    local required = ch.countRequired(item.ClassName, inventory_counts)
    local have = inventory_counts[item.ClassName] or 0

    if required == 0 then
        if not config.show_no_longer_required_items then
            return name
        end
        return string.format(config.no_longer_required_tpl, name)
    elseif have < required then
        return string.format(config.have_lt_required_tpl, have, required, name)
    else
        return string.format(config.have_ge_required_tpl, required, name)
    end

end

function COLLECTIONHELPER_ON_INIT (addon, frame)
    if not loaded then
        buildItemRequirements()
        acutil.setupHook(GET_FULL_NAME, "GET_FULL_NAME")
        acutil.setupHook(LINK_ITEM_TEXT, "LINK_ITEM_TEXT")
        loaded = true
    end

    acutil.log("Collection helper loaded!")
end
