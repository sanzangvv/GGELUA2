-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-13 22:53:47

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM文本 = class('IM文本', IM控件)

function IM文本:初始化()
    self[1] = true
end

function IM文本:更新()
    if self._cr then
        im.TextColored(self.名称, self._cr, self._cg, self._cb, self._ca)
    elseif self.是否禁止 then
        im.TextDisabled(self.名称)
    else
        im.TextUnformatted(self.名称)
    end
    IM控件.更新_(self)
end

function IM文本:置颜色(r, g, b, a)
    self._cr = r and (r / 255) or 1
    self._cg = g and (g / 255) or 1
    self._cb = b and (b / 255) or 1
    self._ca = a and (a / 255) or 1
end

function IM控件:创建文本(name, ...)
    self[name] = IM文本(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end
return IM文本
