-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:36:08

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM提示 = class('IM提示', IM控件)

function IM提示:初始化()
    self.是否可见 = false
end

function IM提示:_更新()
    im.BeginTooltip()
    IM控件._更新(self)
    im.EndTooltip()
end
--==============================================================================
function IM控件:创建提示(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM提示(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end
return IM提示
