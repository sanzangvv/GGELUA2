-- @Author: baidwwy
-- @Date:   2021-08-22 19:58:16
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-26 11:42:28

local SDL = require 'SDL'
local GUI控件 = require('GUI.控件')

local GUI网格 = class('GUI网格', GUI控件)

function GUI网格:初始化()
    self._id = 0
end

local _格子 = class('GUI格子', GUI控件) --继承一下，防止控件接收掉消息
function GUI网格:添加格子(x, y, w, h)
    self._id = self._id + 1
    local id = self._id

    local 格子 = _格子(id, x, y, w, h, self)
    self[id] = 格子
    格子._id = id
    if type(self.子初始化) == 'function' then
        格子.初始化 = function()
            self:子初始化(id)
        end
    end
    if type(self.子更新) == 'function' then
        格子.更新 = function(_, dt)
            self:子更新(dt, id)
        end
    end
    if type(self.子显示) == 'function' then
        格子.显示 = function(_, x, y)
            self:子显示(x, y, id)
        end
    end
    格子:置可见(true)

    table.insert(self.子控件, 格子)
    return 格子
end

function GUI网格:创建格子(宽度, 高度, 行间距, 列间距, 行数量, 列数量)
    for _, v in self:遍历控件() do
        if v._id then
            self:删除控件(v._id)
        end
    end

    self._id = 0
    for h = 1, 行数量 do
        for l = 1, 列数量 do
            local r = self:添加格子((l - 1) * (宽度 + 列间距), (h - 1) * (高度 + 行间距), 宽度, 高度)
        end
    end
    return self
end

function GUI网格:置格子检查区域(x, y, w, h)
    for i, v in ipairs(self.子控件) do
        v:置检查区域(x, y, w, h)
    end
    return self
end

function GUI网格:检查格子(x, y)
    if self:检查点(x, y) then
        for i, v in ipairs(self.子控件) do
            if v.是否可见 and v:检查点(x, y) then
                return i, v
            end
        end
    end
end

function GUI网格:绑定滑块(obj)
    self.滑块 = obj
    if obj then
        local 置位置 = obj.置位置
        obj.置位置 = function(this, v)
            if self.高度 > self:取父控件().高度 then
                local max = self.高度 - self:取父控件().高度
                self:置中心(0, -math.floor(max * (this.位置 / this.最大值)))
                置位置(this, v)
            else
                置位置(this, 0)
            end
        end
    end
    return obj
end

function GUI网格:_消息事件(msg)
    if not self.是否可见 then
        return
    end

    GUI控件._消息事件(self, msg)

    if not msg.鼠标 then
        return
    end

    for _, v in ipairs(msg.鼠标) do
        if v.type == SDL.MOUSE_DOWN then
            local a, b = self:检查格子(v.x, v.y)
            if a then
                v.typed, v.type = v.type, nil
                v.control = self

                if not self.是否禁止 then
                    local x, y, r = b:取坐标()
                    if v.button == SDL.BUTTON_LEFT then
                        self._ldown = a
                        r = self:发送消息('左键按下', x, y, a, b, msg)
                    elseif v.button == SDL.BUTTON_RIGHT then
                        self._rdown = a
                        r = self:发送消息('右键按下', x, y, a, b, msg)
                    end
                    if not msg.win and not r then
                        v.type = v.typed
                    end
                end
            end
        elseif v.type == SDL.MOUSE_UP then
            local a, b = self:检查格子(v.x, v.y)
            if a then
                v.typed, v.type = v.type, nil
                v.control = self

                if not self.是否禁止 then
                    local x, y, r = b:取坐标()
                    if v.button == SDL.BUTTON_LEFT then
                        if self._ldown == a then
                            r = self:发送消息('左键弹起', x, y, a, b, msg)
                        end
                        if v.clicks == 2 then
                            r = self:发送消息('左键双击', x, y, a, b, msg)
                        end
                    elseif v.button == SDL.BUTTON_RIGHT then
                        if self._rdown == a then
                            r = self:发送消息('右键弹起', x, y, a, b, msg)
                        end
                        if v.clicks == 2 then
                            r = self:发送消息('右键双击', x, y, a, b, msg)
                        end
                    end
                    if not msg.win and not r then
                        v.type = v.typed
                    end
                end
            end
            self._ldown = nil
            self._rdown = nil
        elseif v.type == SDL.MOUSE_MOTION then
            if v.state == 0 then
                local a, b = self:检查格子(v.x, v.y)
                if a then
                    v.typed, v.type = v.type, nil
                    v.control = self
                    self._focus = true
                    local x, y = b:取坐标()
                    self:发送消息('获得鼠标', x, y, a, b, msg)
                elseif self._focus then
                    self._focus = nil
                    self:发送消息('失去鼠标', v.x, v.y, msg)
                end
            end
        end
    end
end

function GUI控件:创建网格(name, x, y, w, h)
    assert(not self[name], name .. ':此网格已存在，不能重复创建.')
    self[name] = GUI网格(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end

return GUI网格
