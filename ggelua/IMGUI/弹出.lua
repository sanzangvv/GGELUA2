-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:32:34

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM弹出 = class('IM弹出', IM控件)

function IM弹出:初始化()
    self._tp = 2
    self.是否可见 = false
end

function IM弹出:_更新(dt)
    local r
    if self._tp == 1 then
        r = im.BeginPopup(self.名称, 0)
    elseif self._tp == 2 then
        r = im.BeginPopupContextItem()
    elseif self._tp == 3 then
        r = im.BeginPopupContextWindow()
    end

    if r then
        IM控件._更新(self, dt)
        im.EndPopup()
        return true
    end
end

function IM弹出:置可见(b)
    if not b then
        im.CloseCurrentPopup()
    end
end
--==============================================================================
function IM控件:创建弹出(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM弹出(name, ...)
    table.insert(self._子控件, self[name])
    self[name]._tp = 1
    return self[name]
end

return IM弹出
