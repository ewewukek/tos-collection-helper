class_lists = {}
class_tables = {}

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
    for i, item_name in ipairs({...}) do
        add_object("Item", item_name)
        collection["ItemName_"..i] = item_name
    end
    return collection
end

function add_recipe (result_name, ...)
    local recipe = add_object("Recipe", "r_"..result_name)
    recipe.TargetItem = result_name
    local args = {...}
    if #args % 2 ~= 0 then
        error("add_recipe: odd number of arguments")
    end
    for i = 1, #args / 2 do
        local item_name = args[i * 2 - 1]
        add_object("Item", item_name)
        recipe["Item_"..i.."_1"] = item_name
        recipe["Item_"..i.."_1_count"] = args[i * 2]
    end
    return recipe
end

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