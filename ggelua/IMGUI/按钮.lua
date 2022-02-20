-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:28:36

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM按钮 = class('IM按钮', IM控件)

function IM按钮:初始化()
    self._tp = 1
end

function IM按钮:_更新(dt)
    local r
    if self._tp == 1 then
        if im.Button(self.名称, self._w, self._h) then
            self:发送消息('左键事件')
        end
    elseif self._tp == 2 then
        if im.RadioButton(self.名称, self) then
            self.是否选中 = self[1]
            self:发送消息('选中事件', self[1])
        end
    elseif self._tp == 3 then
        if im.Checkbox(self.名称, self) then
            self.是否选中 = self[1]
            self:发送消息('选中事件', self[1])
        end
    elseif self._tp == 4 then
    --r=im.ImageButton(ptr)
    end
    IM控件._检查鼠标(self)
end

function IM按钮:置选中(v)
    self[1] = v == true
    return self
end
--==============================================================================
function IM控件:创建按钮(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM按钮(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

function IM控件:创建单选按钮(name, ...)
    local r = self:创建按钮(name, ...)
    r._tp = 2
    return r
end

function IM控件:创建多选按钮(name, ...)
    local r = self:创建按钮(name, ...)
    r._tp = 3
    return r
end
return IM按钮
