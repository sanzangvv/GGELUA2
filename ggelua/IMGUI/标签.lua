-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-11 22:08:41

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM标签选项 = class('IM标签选项', IM控件)
function IM标签选项:初始化()
    self[1] = true
end

function IM标签选项:更新()
    if im.BeginTabItem(self.名称) then
        IM控件.更新(self)
        im.EndTabItem()
    end
end

--=====================================================
local IM标签 = class('IM标签', IM控件)

function IM标签:初始化()
end

function IM标签:更新()
    if im.BeginTabBar(self.名称) then
        IM控件.更新(self)
        im.EndTabBar()
    end
    --ImGuiTabBarFlags_NoTooltip
end

function IM标签:添加(name)
    local obj = IM标签选项(name)
    table.insert(self._子控件, obj)
    return obj
end

function IM控件:创建标签(name, ...)
    self[name] = IM标签(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

return IM标签
