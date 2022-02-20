-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:30:01

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM菜单 = class('IM菜单', IM控件)

function IM菜单:初始化()
    self._tp = 1
end

function IM菜单:_更新(dt)
    if self._tp == 1 then
        if im.BeginMainMenuBar() then
            IM控件._更新(self, dt)
            im.EndMainMenuBar()
        end
    elseif self._tp == 2 then
        if im.BeginMenuBar() then
            IM控件._更新(self, dt)
            im.EndMenuBar()
        end
    elseif self._tp == 3 then
        if im.BeginMenu(self.名称, self.是否禁止) then
            IM控件._更新(self, dt)
            im.EndMenu()
        end
    elseif self._tp == 4 then
        if im.MenuItem(self.名称, self._shortcut, self, self.是否禁止) then
            self.是否选中 = self[1]
            self:发送消息('左键事件')
        end
    end
end

function IM菜单:置选中(v)
    self[1] = v == true
    return self
end
--==============================================================================
function IM控件:创建主菜单栏(name, ...) --BeginMainMenuBar
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM菜单(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

function IM控件:创建菜单栏(name, ...) --BeginMenuBar
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM菜单(name, ...)
    table.insert(self._子控件, self[name])
    self[name]._tp = 2
    return self[name]
end

function IM控件:创建菜单(name, ...) --BeginMenu
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM菜单(name, ...)
    table.insert(self._子控件, self[name])
    self[name]._tp = 3
    return self[name]
end

function IM控件:创建菜单项(name, ...) --MenuItem
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM菜单(name, ...)
    table.insert(self._子控件, self[name])
    self[name]._tp = 4
    return self[name]
end
return IM菜单
