-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-13 22:53:20

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM输入 = class('IM输入', IM控件)

function IM输入:初始化()
    self[1] = true
    --self._flag = 0
    self._tp = 1
    self._len = 128
    self._buf = {'', self._len}
end

function IM输入:更新()
    local r
    if self._tp == 1 then
        r = im.InputText(self.名称, self._buf)
    elseif self._tp == 2 then
        r = im.InputTextMultiline(self.名称, self._buf, self.宽度, self.高度, self._flag)
    elseif self._tp == 3 then
        r = im.InputFloat(self.名称, self._buf)
    elseif self._tp == 4 then
        r = im.InputInt(self.名称, self._buf)
    end
    IM控件.更新_(self)
    if r then
        self:发送消息('输入事件',self._buf[1])
    end
end

function IM输入:置文本(v)
    self._buf = {v, self._len}
    return self
end

function IM输入:置最大输入(v)
    self._len = v
    return self
end

function IM输入:置文本模式()
    self._tp = 1
    self._buf = {'', self._len}
    return self
end

function IM输入:置多行模式()
    self._tp = 2
    self._len = 512
    self._buf = {'', self._len}
    return self
end

function IM输入:置数值模式()
    self._tp = 3
    self._buf = {0}
    return self
end

function IM输入:置整数模式()
    self._tp = 4
    self._buf = {0}
    return self
end

function IM控件:创建输入(name, ...)
    self[name] = IM输入(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

function IM控件:创建多行输入(name, ...)
    self[name] = IM输入(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]:置多行模式()
end

function IM控件:创建整数输入(name, ...)
    self[name] = IM输入(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]:置整数模式()
end


function IM控件:创建数值输入(name, ...)
    self[name] = IM输入(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]:置数值模式()
end
return IM输入
