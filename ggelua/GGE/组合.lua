-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-07 03:04:28

--==================================================================================
--将多个对象添加到一起显示
--==================================================================================
local GGE组合 = class('GGE组合')

function GGE组合:GGE组合(...)
    self._list = {...}
    for i, v in ipairs(self._list) do
        assert(type(v) == 'table', '不是表')
        assert(type(v.显示) == 'function', '没有显示方法')
    end
end

function GGE组合:更新(dt)
    for i, v in ipairs(self._list) do
        if type(v.更新) == 'function' then
            v:更新(dt)
        end
    end
end

function GGE组合:显示(x, y)
    for i, v in ipairs(self._list) do
        v:显示(x, y)
    end
end

function GGE组合:添加(t)
    if type(t) == 'table' then
        if ggetype(t) == 'SDL纹理' then
            table.insert(self._list, require('SDL.精灵')(t))
        elseif ggetype(t) == 'SDL精灵' then
            table.insert(self._list, t)
        end
    end
end

function GGE组合:清空()
    self._list = {}
end

function GGE组合:取纹理()
end
return GGE组合
