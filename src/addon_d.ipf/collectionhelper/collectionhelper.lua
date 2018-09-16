local acutil = require('acutil')

local item_requirements = {}

local function makeItemRequirement (item_id)
    if item_requirements[item_id] == nil then
        item_requirements[item_id] = {
            collections = {},
            crafts = {},
        }
    end
    return item_requirements[item_id]
end

local function addCollectionRequirement (item_id, collection_id)
    local item_req = makeItemRequirement(item_id)

    for _, col_req in ipairs(item_req.collections) do
        if col_req.id == collection_id then
            col_req.count = col_req.count + 1
            return
        end
    end

    table.insert(item_req.collections, {
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

            local class_name = TryGetProp(collection, "ItemName_"..j)
            if class_name == nil or class_name == "None" then
                break
            end

            local item_class = GetClass("Item", class_name)
            if item_class == nil then
                break
            end

            addCollectionRequirement(item_class.ClassID, collection.ClassID)
        end
    end
end

local function countRequiredForCollections (item_id, collections)
    local player_collections = session.GetMySession():GetCollection()
    local required = 0

    for _, col_req in ipairs(collections) do
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
    local item_req = item_requirements[item_id]
    if item_req == nil then
        return 0
    end

    local required = 0

    required = required + countRequiredForCollections(item_id, item_req.collections)

    return required
end

local function GET_FULL_NAME (item_class, ...)
    local name = _G['GET_FULL_NAME_OLD'](item_class, ...)

    local required = countRequired(item_class.ClassID)
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
