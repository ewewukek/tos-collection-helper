local acutil = require('acutil')

_G["COLLECTIONHELPER"] = _G["COLLECTIONHELPER"] or {}
local ch = _G["COLLECTIONHELPER"]
ch.collection_items = {}

local function addCollectionRequirement (item_id, collection_id)
    ch.collection_items[item_id] = ch.collection_items[item_id] or {}
    local id_count_list = ch.collection_items[item_id]

    for _, col_req in ipairs(id_count_list) do
        if col_req.id == collection_id then
            col_req.count = col_req.count + 1
            return
        end
    end

    table.insert(id_count_list, {
        id = collection_id,
        count = 1,
    })
end

local function buildItemRequirements ()
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
