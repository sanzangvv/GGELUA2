-- @Author: baidwwy
-- @Date:   2021-08-14 12:39:47
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-28 14:39:55

local SDL = require 'SDL'
local GUI控件 = require('GUI.控件')

local GUI按钮 = class('GUI按钮', GUI控件)

do
    function GUI按钮:初始化(_, x, y, w, h)
        self._rbtn = 1 --用来读
        self.宽度 = w or 0
        self.高度 = h or 0
        local spr = {}
        self._btnspr =
            setmetatable(
            {},
            {
                __index = spr,
                __newindex = function(t, k, v) --控件变量 _spr
                    assert(type(v) == 'table', '对象错误')
                    assert(v.显示, '对象错误')

                    if k == self._rbtn then
                        self._curspr = v
                    end
                    if v.宽度 > self.宽度 or v.高度 > self.高度 then
                        self:置宽高(v.宽度, v.高度)
                    end
                    --rawset(t, k, v)
                    spr[k] = v
                end
            }
        )
    end

    -- function GUI按钮:__index(k)
    --     if k=='_btn' then
    --         return self._rbtn
    --     end
    -- end

    function GUI按钮:__newindex(k, v)
        if k == '_btn' then --用来写
            rawset(self, '_curspr', self._btnspr[v] or self._btnspr[1])
            rawset(self, '_rbtn', v)
            return
        end
        rawset(self, k, v)
    end

    function GUI按钮:_更新(dt)
        GUI控件._更新(self, dt)
        if self._curspr and self._curspr.更新 then
            self._curspr:更新(dt)
        end
    end

    function GUI按钮:_显示(...)
        local _x, _y = self:取坐标()
        self._win:置区域(_x, _y, self.宽度, self.高度)
        if self._curspr then
            self._curspr:显示(_x, _y)
        end
        self._win:置区域()
        GUI控件._显示(self, ...)
    end

    function GUI按钮:置禁止精灵(v)
        self._btnspr[0] = v
        return self
    end

    function GUI按钮:置正常精灵(v)
        self._btnspr[1] = v
        return self
    end

    function GUI按钮:置按下精灵(v)
        self._btnspr[2] = v
        return self
    end

    function GUI按钮:置经过精灵(v)
        self._btnspr[3] = v
        return self
    end

    function GUI按钮:检查点(x, y)
        return self._curspr and self._curspr:检查点(x, y)
    end

    function GUI按钮:检查透明(x, y)
        if gge.platform == 'Android' or gge.platform == 'iOS' then
            return self._curspr and self._curspr:检查点(x, y)
        end
        return self._curspr and self._curspr:取透明(x, y) ~= 0
    end

    function GUI按钮:置可见(v, s)
        GUI控件.置可见(self, v, s)
        if gge.platform == 'Windows' and v and not self.是否禁止 and self._win:取鼠标焦点() then
            local _, x, y = self._win:取鼠标状态()
            if self:检查透明(x, y) then
                self._btn = 3
            else
                self._btn = 1
            end
        end
        return self
    end

    function GUI按钮:置禁止(v)
        self.是否禁止 = v == true
        if self.是否禁止 then
            self._btn = 0
        else
            self._btn = 1
        end
        return self
    end

    local _state = {禁止 = 0, 正常 = 1, 按下 = 2, 经过 = 3, [0] = '禁止', '正常', '按下', '经过'}
    function GUI按钮:取状态()
        return _state[self._rbtn]
    end

    function GUI按钮:置状态(v)
        if _state[v] then
            self._btn = _state[v]
        end
    end

    function GUI按钮:_消息事件(msg)
        if not self.是否可见 then
            return
        end
        GUI控件._消息事件(self, msg)

        if not msg.鼠标 then
            return
        end

        for _, v in ipairs(msg.鼠标) do
            if v.type == SDL.MOUSE_DOWN then
                if v.button == SDL.BUTTON_LEFT or v.button == SDL.BUTTON_RIGHT then
                    if self:检查透明(v.x, v.y) then
                        v.typed, v.type = v.type, nil
                        v.control = self

                        if not self.是否禁止 then
                            self._btn = 2
                            msg.按钮按下 = self
                            local x, y = self:取坐标()
                            if v.button == SDL.BUTTON_LEFT then
                                self:发送消息('左键按下', x, y, msg)
                            elseif v.button == SDL.BUTTON_RIGHT then
                                self:发送消息('右键按下', x, y, msg)
                            end
                        end
                    end
                end
            elseif v.type == SDL.MOUSE_UP then
                if v.button == SDL.BUTTON_LEFT or v.button == SDL.BUTTON_RIGHT then
                    if self:检查透明(v.x, v.y) then
                        if self._rbtn == 2 then
                            v.typed, v.type = v.type, nil
                            v.control = self

                            if not self.是否禁止 then
                                self._btn = 3
                                local x, y = self:取坐标()
                                if v.button == SDL.BUTTON_LEFT then
                                    if self:发送消息('左键弹起', x, y, msg) ~= false then --阻止选中
                                        msg.按钮弹起 = self --已经按下
                                    end
                                elseif v.button == SDL.BUTTON_RIGHT then
                                    self:发送消息('右键弹起', x, y, msg)
                                end
                            end
                        else
                            msg.鼠标弹起 = self --没有按下
                        end
                    elseif self._rbtn == 2 then
                        self._btn = 1
                    end
                end
            elseif v.type == SDL.MOUSE_MOTION then
                if gge.platform == 'Windows' and v.state == 0 then
                    if self:检查透明(v.x, v.y) then
                        self.鼠标焦点 = true
                        local x, y = self:取坐标()
                        self:发送消息('获得鼠标', x, y, msg)
                        v.x = -9999
                        v.y = -9999
                        if not self.是否禁止 and self._rbtn == 1 then
                            self._btn = 3
                            msg.按钮经过 = self
                        end
                    elseif self._rbtn == 3 then
                        self._btn = 1
                        msg.按钮经过 = false
                        self:发送消息('失去鼠标', v.x, v.y, msg)
                        self.鼠标焦点 = false
                    end
                end
            end
        end
    end
end

function GUI控件:创建按钮(name, x, y, w, h)
    assert(not self[name], name .. ':此按钮已存在，不能重复创建.')
    self[name] = GUI按钮(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end
--======================================================================
local GUI多选按钮 = class('GUI多选按钮', GUI按钮)
do
    function GUI多选按钮:初始化()
        self.是否选中 = false

        local spr1 = {}
        self._btnspr1 =
            setmetatable(
            {},
            {
                __index = spr1,
                __newindex = function(t, k, v)
                    assert(type(v) == 'table', '对象错误')
                    assert(v.显示, '对象错误')

                    if not self.是否选中 and k == self._rbtn then
                        self._curspr = v
                    end
                    if v.宽度 > self.宽度 or v.高度 > self.高度 then
                        self:置宽高(v.宽度, v.高度)
                    end
                    --rawset(t, k, v)
                    spr1[k] = v
                end
            }
        )

        local spr2 = {}
        self._btnspr2 =
            setmetatable(
            {},
            {
                __index = spr2,
                __newindex = function(t, k, v)
                    assert(type(v) == 'table', '对象错误')
                    assert(v.显示, '对象错误')

                    if self.是否选中 and k == self._rbtn then
                        self._curspr = v
                    end
                    if v.宽度 > self.宽度 or v.高度 > self.高度 then
                        self:置宽高(v.宽度, v.高度)
                    end
                    --rawset(t, k, v)
                    spr2[k] = v
                end
            }
        )
        self._btnspr = self._btnspr1
    end

    GUI多选按钮.__newindex = GUI按钮.__newindex

    function GUI多选按钮:置禁止精灵(v)
        self._btnspr1[0] = v
        return self
    end

    function GUI多选按钮:置正常精灵(v)
        self._btnspr1[1] = v
        return self
    end

    function GUI多选按钮:置按下精灵(v)
        self._btnspr1[2] = v
        return self
    end

    function GUI多选按钮:置经过精灵(v)
        self._btnspr1[3] = v
        return self
    end

    function GUI多选按钮:置选中禁止精灵(v)
        self._btnspr2[0] = v
        return self
    end

    function GUI多选按钮:置选中正常精灵(v)
        self._btnspr2[1] = v
        return self
    end

    function GUI多选按钮:置选中按下精灵(v)
        self._btnspr2[2] = v
        return self
    end

    function GUI多选按钮:置选中经过精灵(v)
        self._btnspr2[3] = v
        return self
    end

    function GUI多选按钮:置选中(v)
        self.是否选中 = v == true
        self._btnspr = v and self._btnspr2 or self._btnspr1

        self._curspr = self._btnspr[self._rbtn] or self._btnspr[1]

        if self.是否实例 and self.是否可见 and not self._lock then
            self._lock = true --防止循环
            self:发送消息('选中事件', self.是否选中)
            self._lock = nil
        end
        return self
    end

    function GUI多选按钮:_消息事件(msg)
        GUI按钮._消息事件(self, msg)
        if msg.按钮弹起 == self then
            msg.按钮选中 = self
            self:置选中(not self.是否选中)
        end
    end
end

function GUI控件:创建多选按钮(name, x, y, w, h)
    assert(not self[name], name .. ':此按钮已存在，不能重复创建.')
    self[name] = GUI多选按钮(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end
--======================================================================
local GUI单选按钮 = class('GUI单选按钮', GUI多选按钮)

GUI单选按钮.__newindex = GUI按钮.__newindex

function GUI单选按钮:置选中(v)
    if v == true then
        for _, v in ipairs(self.父控件.子控件) do
            if v ~= self and ggetype(v) == 'GUI单选按钮' then
                GUI多选按钮.置选中(v, false)
            end
        end
        GUI多选按钮.置选中(self, true)
    end
    return self
end

function GUI控件:创建单选按钮(name, x, y, w, h)
    assert(not self[name], name .. ':此按钮已存在，不能重复创建.')
    self[name] = GUI单选按钮(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end
