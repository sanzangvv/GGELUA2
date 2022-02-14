-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-11 22:15:46

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM弹出 = class('IM弹出', IM控件)

function IM弹出:初始化()
    self._tp = 2
end

function IM弹出:更新(...)
    local r
    if self._tp == 1 then
        r = im.BeginPopup(self.名称, 0)
    elseif self._tp == 2 then
        r = im.BeginPopupContextItem()
    elseif self._tp == 3 then
        r = im.BeginPopupContextWindow()
    end

    if r then
        IM控件.更新(self,...)
        im.EndPopup()
        return true
    end
end

function IM弹出:置可见(b)
    if not b then
        im.CloseCurrentPopup()
    end
end

function IM控件:创建弹出(name, ...)
    self[name] = IM弹出(name, ...)
    table.insert(self._子控件, self[name])
    self[name]._tp = 1
    return self[name]
end

return IM弹出
