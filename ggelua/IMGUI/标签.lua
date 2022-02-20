-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:29:08

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM标签选项 = class('IM标签选项', IM控件)
function IM标签选项:初始化()
end

function IM标签选项:_更新(dt)
    if im.BeginTabItem(self.名称) then
        IM控件._更新(self)
        im.EndTabItem()
    end
end

--=====================================================
local IM标签 = class('IM标签', IM控件)

function IM标签:初始化()
end

function IM标签:_更新(dt)
    if im.BeginTabBar(self.名称) then
        IM控件._更新(self)
        im.EndTabBar()
    end
    --ImGuiTabBarFlags_NoTooltip
end

function IM标签:添加(name)
    local obj = IM标签选项(name)
    table.insert(self._子控件, obj)
    return obj
end
--==============================================================================
function IM控件:创建标签(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM标签(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

return IM标签
