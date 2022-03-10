-- @Author       : GGELUA
-- @Date         : 2021-09-17 08:26:43
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-10 09:45:35

local _CLASS, _METAS = package.loaded, {}
local type = type
local ipairs = ipairs

local getmetatable = getmetatable
local setmetatable = setmetatable
local unpack = table.unpack

local assert = assert
local pcall = pcall
local xpcall = xpcall

--类()  语法糖
local function class_call(cobj, ...)
    return cobj.创建(...)
end
--类.创建()，递归所有父初始化
local function class_new(self, cobj, meta, ...)
    local super = meta.__super
    if super then
        for _, v in ipairs(super) do
            class_new(self, v, _METAS[v], ...)
        end
    end
    if cobj.初始化 then
        return cobj.初始化(self, ...)
    end
end
--类:方法()索引
local function class_index(self, k, meta)
    if not meta then
        meta = getmetatable(self)
    end
    --self[class]:XXX()指定类方法
    if meta.__cobj then
        local r = meta.__cobj[k]
        meta.__cobj = nil
        return r
    elseif _METAS[k] then --self[class]
        meta.__cobj = _METAS[k]
        return self
    end

    local r = meta[k] --自身方法
    if r == nil and meta.__super then --找父方法
        for _, cobj in ipairs(meta.__super) do
            r = cobj.__index(self, k, _METAS[cobj])
            if r ~= nil then
                return r
            end
        end
    end
    return r
end
--检验是否是类(因为_CLASS是package.loaded,所以可能会出现冲突)
local function assert_class(t)
    if type(t) == 'table' then
        if getmetatable(t) == 'ggeclass' then
            return t
        end
    end
    error('非class')
end
--检验父类是否正确
local function assert_super(t)
    if type(t) == 'table' and #t > 0 then
        for i, v in ipairs(t) do
            if type(v) == 'string' then --用类名索引
                assert_class(_CLASS[v])
                t[i] = _CLASS[v]
            elseif type(v) == 'table' then
                assert_class(v)
            else
                error('错误的父参数')
            end
            --t[v] = _METAS[v]--用于重载后调用父函数
        end
        return t
    end
end

local function class(name, ...)
    assert(type(name) == 'string', '必须要有类名')
    assert(_CLASS[name] == nil, name .. ':类名已经存在')
    local meta, cobj
    meta = {
        __name = name,
        __index = class_index,
        __super = assert_super {...}
    }
    meta.__metatable = meta --禁止修改
    cobj = {
        --初始化 = false,[name] = false,
        创建 = function(...)
            local obj, ret = (setmetatable({}, meta))
            if cobj[name] then --初始化
                ret = {cobj[name](obj, ...)}
            end

            if not ret then
                ret = {class_new(obj, cobj, meta, ...)}
            end

            if ret[1] == false then
                return table.unpack(ret)
            end
            return obj, table.unpack(ret)
        end
    }
    --_METAS[name]   = meta
    _METAS[cobj] = meta --_METAS[class] = meta
    _CLASS[name] = cobj --package.loaded
    return setmetatable(
        cobj,
        {
            __index = meta,
            __call = class_call,
            __name = 'ggeclass',
            __metatable = 'ggeclass',
            __newindex = function(t, k, value)
                if k == '__super' then
                    value = assert_super(value)
                elseif k == '__gc' then
                    if type(value) == 'function' then
                        meta.__gc = function(t)
                            value(t)
                            local super = meta.__super
                            if super then
                                for i = #super, 1, -1 do
                                    local v = super[i]
                                    if _METAS[v].__gc then
                                        _METAS[v].__gc(t)
                                    end
                                end
                            end
                        end
                        return
                    else
                        error('not a function')
                    end
                elseif k == '__index' then
                    if type(value) == 'table' then
                        meta.__index = function(t, k, m)
                            local r = class_index(t, k, m)
                            if r == nil then
                                return value[k]
                            end
                            return r
                        end
                    elseif type(value) == 'function' then
                        meta.__index = function(t, k, m)
                            local r = class_index(t, k, m) --先判断类属性或方法不存在
                            if r == nil then
                                return value(t, k) --外部定义
                            end
                            return r
                        end
                    else
                        error('not a function or table')
                    end
                    return
                -- elseif k == '__newindex' then
                --     if type(value) == 'function' then
                --         meta.__newindex = function(t, k, v)
                --             local r = class_index(t, k)  --先判断类属性或方法不存在
                --             if r == nil then
                --                 value(t, k, v)  --外部定义
                --             else
                --                 rawset(t, k, v)
                --             end
                --         end
                --     end
                --     return
                end
                meta[k] = value
            end
        }
    )
end

return class
