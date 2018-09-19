require("oop")

-- utility methods

function imc_reset()
    class_lists = {}
    class_tables = {}
    geCollectionTable.collections = {}
    session = Session:new() -- imc's global table
end

function class_id2name (class, id)
    return class_lists[class][id].ClassName
end

function add_object (class, name, strict)
    class_lists[class] = class_lists[class] or {}
    local list = class_lists[class]

    class_tables[class] = class_tables[class] or {}
    local tabl = class_tables[class]

    if tabl[name] ~= nil then
        return
    end

    local object = {
        ClassID = #list + 1,
        ClassName = name,
        Name = name,
    }

    table.insert(list, object)
    tabl[name] = object

    return object
end

function add_collection (name, ...)
    local collection = add_object("Collection", name)
    local col_info = CollectionInfo:new()
    for i, item_name in ipairs({...}) do
        add_object("Item", item_name)
        collection["ItemName_"..i] = item_name
        col_info:add(item_name)
    end
    geCollectionTable.collections[name] = col_info
    return collection
end

function add_recipe (result_name, ...)
    local recipe = add_object("Recipe", "r_"..result_name)
    recipe.TargetItem = result_name
    for i, pair in ipairs({...}) do
        local item_name = pair[1]
        add_object("Item", item_name)
        recipe["Item_"..i.."_1"] = item_name
        recipe["Item_"..i.."_1_count"] = pair[2]
    end
    return recipe
end

function add_to_player_collection (collection_id, ...)
    local pl_col = session.collections:add(collection_id)
    for _, item_id in ipairs({...}) do
        pl_col:add(item_id)
    end
end

function add_to_player_inventory (item_id, count)
    count = count or 1
    session.inventory:add(InventorySlot:new("Item", item_id, count))
end

-- imc compatible classes

CollectionInfo = inherits(nil)

function CollectionInfo:init ()
    self.items = {}
end

function CollectionInfo:add (item_id)
    table.insert(self.items, item_id)
end

function CollectionInfo:GetTotalItemCount ()
    return #self.items
end

function CollectionInfo:GetNeedItemCount (item_id)
    item_id = class_id2name("Item", item_id)
    local count = 0
    for _, id in ipairs(self.items) do
        if id == item_id then
            count = count + 1
        end
    end
    return count
end

---

PlayerCollection = inherits(CollectionInfo);

PlayerCollection.GetItemCount = CollectionInfo.GetTotalItemCount
PlayerCollection.GetItemCountByType = CollectionInfo.GetNeedItemCount

---

SessionCollections = inherits(nil)

function SessionCollections:Get (collection_id)
    collection_id = class_id2name("Collection", collection_id)
    return self["_"..collection_id]
end

function SessionCollections:add (collection_id)
    self["_"..collection_id] = PlayerCollection:new()
    return self["_"..collection_id]
end

---

InventorySlot = inherits(nil)

function InventorySlot:init (class, id, count)
    self.class = class
    self.id = id
    self.count = count
end

function InventorySlot:GetObject ()
    return GetClass (self.class, self.id)
end

---

IndexedList = inherits(nil)

function IndexedList:init ()
    self.list = {}
end

function IndexedList:add (value)
    table.insert(self.list, value)
end

function IndexedList:Head ()
    if #self.list == 0 then
        return self.InvalidIndex()
    end
    return 1
end

function IndexedList:InvalidIndex ()
    return -1
end

function IndexedList:Element (index)
    return self.list[index]
end

function IndexedList:Next (index)
    if index >= #self.list then
        return self.InvalidIndex()
    end
    return index + 1
end

---

Session = inherits(nil)

function Session:init ()
    self.collections = SessionCollections:new()
    self.inventory = IndexedList:new()
end

function Session.GetMySession ()
    return session
end

function Session:GetCollection ()
    return session.collections
end

function Session.GetInvItemList ()
    return session.inventory
end

-- imc's global functions and tables

function GetClassList (name)
    local list = class_lists[name]
    if list == nil then
        return nil, 0
    end
    return list, #list
end

function GetClassByIndexFromList (list, index)
    return list[index + 1]
end

function GetClass (class, name)
    local tabl = class_tables[class]
    if tabl == nil then
        return nil
    end
    return tabl[name]
end

function TryGetProp (object, property)
    return object[property]
end

function GET_RECIPE_REQITEM_CNT (recipe, prop_name)
    return recipe[prop_name.."_count"]
end

geCollectionTable = {
    Get = function (collection_id)
        return geCollectionTable.collections[class_id2name("Collection", collection_id)]
    end,
}

function GetIES (object)
    return object
end
