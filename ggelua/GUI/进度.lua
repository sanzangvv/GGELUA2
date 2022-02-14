-- @Author: baidwwy
-- @Date:   2021-08-18 13:24:54
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-17 00:34:53

local SDL = require 'SDL'
local GUI控件 = require('GUI.控件')

local GUI进度 = class('GUI进度', GUI控件)

function GUI进度:初始化()
    self.位置 = 0
    self.最大值 = 100
    self.最小值 = 0
end

function GUI进度:置位置(v)
    self.位置 = assert(type(v) == 'number' and v, '非数值')
    local 精灵 = self:取精灵()
    if not 精灵 then
        return
    end
    self.位置 = (v > self.最大值) and self.最大值 or math.floor(v)
    self.位置 = not (v > self.最小值) and self.最小值 or self.位置

    精灵:置区域(0, 0, math.floor(self.位置 / self.最大值 * self.宽度), self.高度)
    return self
end

function GUI进度:置精灵(v)
    local w, h = self.宽度, self.高度
    GUI控件.置精灵(self, v)
    self.宽度, self.高度 = w, h
    self:置位置(self.位置)
end

function GUI进度:_消息事件(msg)
    if not msg.鼠标 then
        return
    end

    for _, v in ipairs(msg.鼠标) do
        if v.type == SDL.MOUSE_DOWN then
            if self:检查点(v.x, v.y) then
                v.typed, v.type = v.type, nil
                v.control = self

                if not self.是否禁止 then
                    if v.button == SDL.BUTTON_LEFT then
                        self._ldown = true
                        local x, y = self:取坐标()
                        self:发送消息('左键按下', x, y, msg)
                    elseif v.button == SDL.BUTTON_RIGHT then
                        self._rdown = true
                        local x, y = self:取坐标()
                        self:发送消息('右键按下', x, y, msg)
                    end
                end
            end
        elseif v.type == SDL.MOUSE_UP then
            if self:检查点(v.x, v.y) then
                v.typed, v.type = v.type, nil
                v.control = self

                if not self.是否禁止 then
                    if v.button == SDL.BUTTON_LEFT then
                        if self._ldown then
                            local x, y = self:取坐标()
                            self:发送消息('左键弹起', x, y, msg)
                        end
                    elseif v.button == SDL.BUTTON_RIGHT then
                        if self._rdown then
                            local x, y = self:取坐标()
                            self:发送消息('右键弹起', x, y, msg)
                        end
                    end
                end
            end
            self._ldown = nil
            self._rdown = nil
        elseif v.type == SDL.MOUSE_MOTION then
            if v.state == 0 then
                if self:检查点(v.x, v.y) then
                    v.typed, v.type = v.type, nil
                    v.control = self
                    self._focus = true
                    local x, y = self:取坐标()
                    self:发送消息('获得鼠标', x, y, msg)
                elseif self._focus then
                    self._focus = nil
                    self:发送消息('失去鼠标', v.x, v.y, msg)
                end
            end
        end
    end
end

function GUI控件:创建进度(name, x, y, w, h)
    assert(not self[name], name .. ':此进度已存在，不能重复创建.')
    self[name] = GUI进度(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end
