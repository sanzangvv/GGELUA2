-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:36:26

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM文本 = class('IM文本', IM控件)

function IM文本:初始化()
end

function IM文本:_更新()
    if self._cr then
        im.TextColored(self.str or self.名称, self._cr, self._cg, self._cb, self._ca)
    elseif self.是否禁止 then
        im.TextDisabled(self.str or self.名称)
    else
        im.TextUnformatted(self.str or self.名称)
    end
    IM控件._检查鼠标(self)
end

function IM文本:置颜色(r, g, b, a)
    self._cr = r and (r / 255) or 1
    self._cg = g and (g / 255) or 1
    self._cb = b and (b / 255) or 1
    self._ca = a and (a / 255) or 1
end

function IM文本:置文本(t)
    self.str = t
end
--==============================================================================
function IM控件:创建文本(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM文本(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end
return IM文本
