class_lists = {}
class_tables = {}

function add_object (class, name, object)
    class_lists[class] = class_lists[class] or {}
    local list = class_lists[class]

    class_tables[class] = class_tables[class] or {}
    local tabl = class_tables[class]

    if tabl[name] ~= nil then
        error(class.." "..name.." already registered")
    end

    object = {table.unpack(object or {})}
    object.ClassID = #list + 1
    object.ClassName = name
    object.Name = name

    table.insert(list, object)
    tabl[name] = object

    return object
end

function add_collection (name, ...)
    local col = add_object("Collection", name)
    for i, item_name in ipairs({...}) do
        col["ItemName_"..i] = item_name
    end
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
