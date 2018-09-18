function inherits( baseClass )

    local new_class = {}

    local class_mt = { __index = new_class }

    function new_class:new(...)
        local newinst = {}
        setmetatable( newinst, class_mt )
        if new_class.init then new_class.init(newinst, ...) end
        return newinst
    end

    if nil ~= baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    function new_class:class()
        return new_class
    end

    function new_class:super()
        return baseClass
    end

    function new_class:instanceOf( theClass )
        local b_isa = false

        local cur_class = new_class

        while (nil ~= cur_class) and (false == b_isa) do
            if cur_class == theClass then
                b_isa = true
            else
                cur_class = cur_class:super()
            end
        end

        return b_isa
    end

    return new_class
end
