-- @Author: baidwwy
-- @Date:   2021-08-18 13:24:54
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-17 00:44:39

local SDL = require 'SDL'
local GUI控件 = require('GUI.控件')

local GUI滑块 = class('GUI滑块', GUI控件)

function GUI滑块:初始化()
    self.位置 = 0
    self.最小值 = 0
    self.最大值 = 100
end

function GUI滑块:创建滑块按钮(name, x, y, w, h)
    self._rect = self:创建控件('_rect', x, y, w or self.宽度, h or self.高度) --按钮的区域
    self._btn2 = self._rect:创建按钮('_btn2')
    self[name] = self._btn2
    return self._btn2
end

function GUI滑块:创建减少按钮(name, ...) --上边或左边
    self._btn1 = self:创建按钮('_btn1', ...)
    self[name] = self._btn1
    return self._btn1
end

function GUI滑块:创建增加按钮(name, ...) --下边或右边
    self._btn3 = self:创建按钮('_btn3', ...)
    self[name] = self._btn3
    return self._btn3
end

function GUI滑块:置位置(v)
    if v < self.最小值 or tostring(v) == '-nan(ind)' or tostring(v) == 'nan' or tostring(v) == 'inf' then
        v = self.最小值
    end
    if v > self.最大值 then
        v = self.最大值
    end

    self.位置 = v

    if self.宽度 > self.高度 then --横向
        local w = self._rect.宽度 - self._btn2.宽度
        self._btn2:置坐标(math.floor(v / self.最大值 * w), 0)
    else
        local h = self._rect.高度 - self._btn2.高度
        self._btn2:置坐标(0, math.floor(v / self.最大值 * h))
    end

    return self
end

local _计算位置 = function(self, _x, _y)
    local x, y, pos = self._rect:取坐标()

    if self.宽度 > self.高度 then --横向
        local w = self._rect.宽度 - self._btn2.宽度
        pos = math.floor((_x - x - self._bx) / w * self.最大值)
    else
        local h = self._rect.高度 - self._btn2.高度
        pos = math.floor((_y - y - self._by) / h * self.最大值)
    end

    if pos ~= self.位置 then
        self:置位置(pos)
        return true
    end
end

function GUI滑块:_消息事件(msg)
    if msg.鼠标 then
        for _, v in ipairs(msg.鼠标) do
            if v.type == SDL.MOUSE_DOWN and v.button == SDL.BUTTON_LEFT then
                if self._btn2:检查点(v.x, v.y) then --在按钮接收事件前，记录鼠标在按钮上的位置
                    local x, y = self._btn2:取坐标()
                    self._bx = v.x - x
                    self._by = v.y - y
                    break
                end
            end
        end
    end

    GUI控件._消息事件(self, msg)

    if self._btn1 and msg.按钮弹起 == self._btn1 then
        self:置位置(self.位置 - 10)
    elseif self._btn3 and msg.按钮弹起 == self._btn3 then
        self:置位置(self.位置 + 10)
    end

    if not msg.鼠标 then
        return
    end

    for _, v in ipairs(msg.鼠标) do
        if v.type == SDL.MOUSE_DOWN then
            if self._rect:检查点(v.x, v.y) and v.button == SDL.BUTTON_LEFT then --点击区域
                v.typed, v.type = v.type, nil
                v.control = self
                self._btn2:置状态('按下')
                self._bx = self._btn2.宽度 // 2
                self._by = self._btn2.高度 // 2
                if _计算位置(self, v.x, v.y) then
                    local x, y = self._btn2:取坐标()
                    self:发送消息('滚动事件', x, y, self.位置, msg)
                end
            end
        elseif v.type == SDL.MOUSE_MOTION and v.state == SDL.BUTTON_LMASK and self._btn2:取状态() == '按下' then --拖动
            if _计算位置(self, v.x, v.y) then
                local x, y = self._btn2:取坐标()
                self:发送消息('滚动事件', x, y, self.位置, msg)
            end
        end
    end
end

function GUI控件:创建滑块(name, x, y, w, h)
    assert(not self[name], name .. ':此滑块已存在，不能重复创建.')
    self[name] = GUI滑块(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end

return GUI滑块
