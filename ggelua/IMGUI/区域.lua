-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:33:01

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM区域 = class('IM区域', IM控件)

function IM区域:初始化()
    self._name = tostring(self)
    --self._frame = true
end

function IM区域:_更新(dt)
    --不需要if
    if self._frame then
        im.BeginChildFrame(self._name, self.宽度, self.高度, self._flag)
    else
        im.BeginChild(self._name, self.宽度, self.高度, self._border, self._flag)
    end

    IM控件._更新(self, dt)
    if self._auto then
        if im.GetScrollY() >= im.GetScrollMaxY() then
            im.SetScrollHereY(1)
        end
    end
    if self._frame then
        im.EndChildFrame()
    else
        im.EndChild()
    end
end

function IM区域:置自动滚动(b)
    self._auto = b
    return self
end

function IM区域:置边框(b)
    self._border = b
    return self
end
--==============================================================================
function IM控件:创建区域(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM区域(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

return IM区域
