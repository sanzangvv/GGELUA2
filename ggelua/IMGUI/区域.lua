-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-11 22:09:09

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM区域 = class('IM区域', IM控件)

function IM区域:初始化()
    self[1] = true
    --self._frame = true
end

function IM区域:更新()
    --不需要if
    if self._frame then
        im.BeginChildFrame(self.名称, self.宽度, self.高度, self._flag)
    else
        im.BeginChild(self.名称, self.宽度, self.高度, self._border, self._flag)
    end

    IM控件.更新(self)
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

function IM控件:创建区域(name, ...)
    self[name] = IM区域(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

return IM区域
