-- @Author: baidwwy
-- @Date:   2021-07-10 16:32:33
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-24 15:44:41

local SDL = require 'SDL'
local GUI控件 = require('GUI.控件')
local GGE文本 = require('GGE.文本')

local GUI文本 = class('GUI文本', GUI控件, GGE文本)

function GUI文本:初始化()
    self._py = 0
    self._max = 0
    GGE文本.GGE文本(self, self.宽度, self.高度)

    self:置文字(self:取根控件()._文字:复制())
end

function GUI文本:_更新(...)
    GUI控件._更新(self, ...)
    GGE文本.更新(self, ...)
end

function GUI文本:_显示(...)
    GUI控件._显示(self, ...)
    local _x, _y = self:取坐标()
    self._win:置区域(_x, _y, self.宽度, self.高度)
    GGE文本.显示(self, _x, _y + self._py)
    self._win:置区域()
    --self.矩形:显示()
end

function GUI文本:置文本(...)
    self._py = 0
    local w, h = GGE文本.置文本(self, ...)
    self._max = h - self.高度
    if self._max < 0 then
        self._max = 0
    end
    return w, h
end

function GUI文本:置宽度(...)
    local w, h = GGE文本.置宽度(self, ...)
    self._max = h - self.高度
    if self._max < 0 then
        self._max = 0
    end
    GUI控件.置宽度(self, ...)
    return w, h
end

function GUI文本:绑定滑块(obj)
    self.滑块 = obj
    if obj then
        local 置位置 = obj.置位置
        obj.置位置 = function(this, v)
            置位置(this, v)
            self._py = -math.floor(this.位置 / this.最大值 * self._max)
            if self._py == 0 then
                置位置(this, 0)
            end
            return self._py ~= 0
        end
    end
    return obj
end

function GUI文本:_消息事件(msg)
    if not self.是否可见 or self.是否禁止 or not msg.鼠标 then
        return
    end

    for _, v in ipairs(msg.鼠标) do
        if v.type == SDL.MOUSE_DOWN then
            if self:检查点(v.x, v.y) then
                local cb = self:检查回调(v.x, v.y)
                if cb then
                    if v.button == SDL.BUTTON_LEFT then
                        self._lcb = cb
                        if rawget(self, '左键按下') then
                            v.typed, v.type = v.type, nil
                            v.control = self
                            self:发送消息('左键按下', cb, msg)
                        end
                    elseif v.button == SDL.BUTTON_RIGHT then
                        self._rcb = cb
                        if rawget(self, '右键按下') then
                            v.typed, v.type = v.type, nil
                            v.control = self
                            self:发送消息('右键按下', cb, msg)
                        end
                    end
                end
            end
        elseif v.type == SDL.MOUSE_UP then
            if self:检查点(v.x, v.y) then
                local cb = self:检查回调(v.x, v.y)
                if cb then
                    if v.button == SDL.BUTTON_LEFT and rawget(self, '回调左键弹起') then
                        if cb == self._lcb then
                            v.typed, v.type = v.type, nil
                            v.control = self
                            self:发送消息('回调左键弹起', cb, msg)
                        end
                    elseif v.button == SDL.BUTTON_RIGHT and rawget(self, '回调右键弹起') then
                        if cb == self._rcb then
                            v.typed, v.type = v.type, nil
                            v.control = self
                            self:发送消息('回调右键弹起', cb, msg)
                        end
                    end
                end
                self._lcb = nil
                self._rcb = nil
            end
        elseif v.type == SDL.MOUSE_MOTION then
            if self:检查点(v.x, v.y) and v.state == 0 then
                local x, y = self:取坐标()
                self:发送消息('获得鼠标', x, y, msg)
                self._mf = true
                local cb = self:检查回调(v.x, v.y)
                if cb then
                    v.typed, v.type = v.type, nil
                    v.control = self
                    self._focus = true
                    self:发送消息('获得回调', v.x, v.y, cb, msg)
                elseif self._focus then
                    self._focus = nil
                    self:发送消息('失去回调', v.x, v.y, msg)
                end
            elseif self._mf then
                self._mf = nil
                self:发送消息('失去鼠标', v.x, v.y, msg)
            end
        elseif v.type == SDL.MOUSE_WHEEL then
            local x, y = SDL._wins[v.windowID]:取鼠标坐标()
            if self:检查点(x, y) and self._max > 0 then
                v.typed, v.type = v.type, nil
                v.control = self
                local py = self._py + v.y * (self.高度 / 2)

                if py > 0 then
                    py = 0
                end

                if math.abs(py) > self._max then
                    py = -self._max
                end

                if self.滑块 then
                    self.滑块:置位置(math.floor(math.abs(py) / self._max * self.滑块.最大值))
                else
                    self._py = math.floor(py)
                end

                self:发送消息('鼠标滚轮', py == -self._max)
            end
        end
    end
end

function GUI控件:创建文本(name, x, y, w, h)
    assert(not self[name], name .. ':此文本已存在，不能重复创建.')
    self[name] = GUI文本(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end

return GUI文本
