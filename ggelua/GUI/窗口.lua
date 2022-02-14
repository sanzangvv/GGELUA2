-- @Author: baidwwy
-- @Date:   2021-07-10 16:32:33
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-17 01:10:33

local SDL = require 'SDL'
local GUI控件 = require('GUI.控件')

local lid = 0
local function _comp(a, b)
    return a._ID < b._ID
end
local function _sort(self)
    lid = lid + 1
    self._ID = lid
    if self.父控件.子控件 then
        table.sort(self.父控件.子控件, _comp)
    else
        warn(self.名称)
    end
end

local GUI窗口 = class('GUI窗口', GUI控件)

function GUI窗口:初始化()
    self._ID = 0

    --负坐标
    self:置中心(self.x, self.y)
    self:置坐标(0, 0)
end

function GUI窗口:置可见(v, s)
    GUI控件.置可见(self, v, s or not self.是否实例)
    if v and self.父控件 then
        _sort(self)
    end
    self:_子控件消息({父窗口可见 = self.是否可见})
    return self
end

function GUI窗口:置坐标(x, y)
    self:置中心(x, y)
    return self
end

function GUI窗口:取窗口()
    return self
end

function GUI窗口:_消息事件(msg)
    if self.是否禁止 and msg.鼠标 then
        for _, v in ipairs(msg.鼠标) do
            if self:检查透明(v.x, v.y) then
                v.x = -9999
                v.y = -9999
            end
        end
        return
    end
    if self:发送消息('消息开始', msg) then
        return
    end
    if self.父控件 and msg.鼠标 then --如果按下，置顶，子控件会吃消息，所以放前面
        for _, v in ipairs(msg.鼠标) do
            if v.type == SDL.MOUSE_DOWN then
                if self:检查透明(v.x, v.y) then
                    _sort(self)
                end
                break
            end
        end
    end
    msg.win = self
    GUI控件._消息事件(self, msg)

    if msg.鼠标 then
        for _, v in ipairs(msg.鼠标) do
            if v.type == SDL.MOUSE_DOWN then
                if self:检查透明(v.x, v.y) then
                    if v.button == SDL.BUTTON_LEFT then
                        local x, y = self:取中心()
                        self._lx, self._ly = v.x - x, v.y - y
                        self._ldown = v.x .. v.y
                        self:发送消息('左键按下', v.x, v.y, msg)
                    elseif v.button == SDL.BUTTON_RIGHT then
                        self._rdown = v.x .. v.y
                        self:发送消息('右键按下', v.x, v.y, msg)
                    end
    
                    v.x = -9999
                    v.y = -9999
                end
            elseif v.type == SDL.MOUSE_UP then
                if self:检查透明(v.x, v.y) then
                    if v.button == SDL.BUTTON_LEFT then
                        if self._ldown == v.x .. v.y then
                            self:发送消息('左键弹起', v.x, v.y, msg)
                        end
                    elseif v.button == SDL.BUTTON_RIGHT then
                        if self._rdown and self:发送消息('右键弹起', v.x, v.y, msg) ~= false then
                            self:置可见(false)
                        end
                    end
                    v.x = -9999
                    v.y = -9999
                end
                self._lx = nil
                self._ly = nil
                self._ldown = nil
                self._rdown = nil
            elseif v.type == SDL.MOUSE_MOTION then
                if self._lx and v.state == SDL.BUTTON_LMASK then
                    self:置中心(v.x - self._lx, v.y - self._ly)
                end
                if self:检查透明(v.x, v.y) then
                    self:发送消息('获得鼠标', v.x, v.y, msg)
                    v.x = -9999
                    v.y = -9999
                end
            end
        end
    end

    if self:发送消息('消息结束', msg) then --非模态
        self:清空消息(msg)
    end
end

function GUI控件:创建窗口(name, x, y, w, h)
    assert(not self[name], name .. ':此窗口已存在，不能重复创建.')
    self[name] = GUI窗口(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end
--===========================================================================
local GUI模态窗口 = class('GUI模态窗口',GUI窗口)

function GUI模态窗口:置可见(b)
    if not self.是否可见 then
        table.insert(self:取根控件()._modal, self)
    end
    GUI窗口.置可见(self,b)
    return self
end

function GUI控件:创建模态窗口(name, x, y, w, h)
    return GUI模态窗口(name, x, y, w, h, self)
end
--===========================================================================
local GUI弹出窗口 = class('GUI弹出窗口',GUI窗口)

function GUI弹出窗口:置可见(b)
    if not self.是否可见 then
        table.insert(self:取根控件()._popup, self)
    end
    GUI窗口.置可见(self,b,true)
    return self
end

function GUI控件:创建弹出窗口(name, x, y, w, h)
    return GUI弹出窗口(name, x, y, w, h, self)
end
return GUI窗口
