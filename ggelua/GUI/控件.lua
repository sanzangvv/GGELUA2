-- @Author: baidwwy
-- @Date:   2021-08-03 06:12:47
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-25 11:10:37

local SDL = require 'SDL'

local GUI控件 = class('GUI控件')

function GUI控件:初始化(name, x, y, w, h, f)
    self.名称 = name
    self.x = math.floor(tonumber(x) or 0)
    self.y = math.floor(tonumber(y) or 0)
    self.宽度 = math.abs(math.floor(tonumber(w) or 0))
    self.高度 = math.abs(math.floor(tonumber(h) or 0))

    self.父控件 = assert(f, '父控件')
    --self._root = self:取根控件()
    self._win = self:取根控件()._win
    self.子控件 = {} --FIXME 优化其它类的引用
    self.是否可见 = false
    --self.是否禁止 = false
    --self.是否实例   = false --是否已经加载

    self.矩形 = require('SDL.矩形')(0, 0, self.宽度, self.高度)
    self.矩形:置颜色(255, 0, 0)
    --self.矩形:置坐标(self:取坐标())
end

function GUI控件:_更新(...)
    if rawget(self, '更新') then
        self:更新(...)
    end
    if self._spr and self._spr.更新 then
        self._spr:更新(...)
    end
    for _, v in ipairs(self.子控件) do
        if v.是否可见 then
            v:_更新(...)
        end
    end
end

function GUI控件:_显示(x, y)
    local _x, _y = self:取坐标() --坐标是相对的，每次获取,TODO：移动才修改
    self.矩形:置坐标(_x, _y)
    if rawget(self, '后显示') then
        self:后显示(_x, _y)
    end

    if self._win:置区域(_x, _y, self.宽度, self.高度) then
        if self._spr then
            self._spr:显示(_x, _y)
        end
        if rawget(self, '显示') then
            self:显示(_x, _y, x, y)
        end
        for _, v in ipairs(self.子控件) do
            if v.是否可见 then
                v:_显示(x, y)
            end
        end

        if gge.isdebug and self._win:取按键状态(SDL.KEY_F1) then
            self.矩形:显示()
        end
        self._win:置区域()
    end
    if rawget(self, '前显示') then
        self:前显示(_x, _y)
    end
end

function GUI控件:_后显示(x, y, mx, my)
    self.矩形:置坐标(x, y)
    if gge.isdebug and self._win:取按键状态(SDL.KEY_F1) then
        self.矩形:显示()
    end
    if rawget(self, '后显示') then
        self:后显示(x, y, mx, my)
    end
    if self._spr then
        self._spr:显示(x, y)
    end
end

function GUI控件:_前显示(x, y, mx, my)
    if rawget(self, '显示') then
        self:显示(x, y, mx, my)
    end
    for _, v in ipairs(self.子控件) do
        if v.是否可见 then
            v:_显示(mx, my)
        end
    end
    if rawget(self, '前显示') then
        self:前显示(x, y, mx, my)
    end
end

function GUI控件:_子控件消息(msg)
    for i = #self.子控件, 1, -1 do
        local v = self.子控件[i]
        if v.是否可见 then
            v:_消息事件(msg)
        end
    end
end

function GUI控件:_消息事件(msg)
    if self.是否禁止 or not self.是否可见 then
        return
    end

    self:_子控件消息(msg)

    if msg.键盘 then
        for _, v in ipairs(msg.键盘) do
            if self:发送消息('键盘事件', table.unpack(v)) then
                v[2] = nil
            end
        end
    end

    if not msg.鼠标 then
        return
    end

    for _, v in ipairs(msg.鼠标) do
        if self:发送消息('鼠标事件', table.unpack(v)) then
        --v[2] = nil
        end
    end

    local tp = ggetype(self)
    if tp == 'GUI控件' or tp == 'GUI弹出控件' then
        for _, v in ipairs(msg.鼠标) do
            if v.type == SDL.MOUSE_DOWN then
                if self:检查点(v.x, v.y) then
                    if v.button == SDL.BUTTON_LEFT then
                        self._ldown = v.x .. v.y
                        self:发送消息('左键按下', v.x, v.y, msg)
                    elseif v.button == SDL.BUTTON_RIGHT then
                        self._rdown = v.x .. v.y
                        self:发送消息('右键按下', v.x, v.y, msg)
                    end

                    if self:检查透明(v.x, v.y) then --窗口下的控件 穿透
                        v.typed, v.type = v.type, nil
                        v.control = self
                    end
                end
            elseif v.type == SDL.MOUSE_UP then
                if self:检查点(v.x, v.y) then
                    if v.button == SDL.BUTTON_LEFT then
                        if self._ldown == v.x .. v.y then
                            self:发送消息('左键弹起', v.x, v.y, msg)
                        end
                    elseif v.button == SDL.BUTTON_RIGHT then
                        if self._rdown then
                            self:发送消息('右键弹起', v.x, v.y, msg)
                        end
                    end

                    if self:检查透明(v.x, v.y) then --窗口下的控件 穿透
                        v.typed, v.type = v.type, nil
                        v.control = self
                    end
                end
                self._ldown = nil
                self._rdown = nil
            elseif v.type == SDL.MOUSE_MOTION then
                if v.state == 0 and self:检查点(v.x, v.y) then
                    self:发送消息('获得鼠标', v.x, v.y, msg)
                    if self:检查透明(v.x, v.y) then
                        v.x = -9998
                        v.y = -9999
                    --v.control = self
                    end
                end
            -- elseif v.type==SDL.MOUSE_WHEEL then
            --     print(self.父控件 and self.父控件.名称,self.名称)
            end
        end

        self:发送消息('消息事件', msg)
        if self:发送消息('消息结束', msg) then
            self:清空消息(msg)
        end
    end
end

function GUI控件:置精灵(v, wh)
    if type(v) == 'table' and type(v.显示) == 'function' then
        self._spr = v
        if wh or self.宽度 == 0 or self.高度 == 0 then
            self.宽度 = v.宽度
            self.高度 = v.高度
            if type(v.取矩形) == 'function' then
                self.矩形 = v:取矩形():复制()
            else
                self.矩形 = require('SDL.矩形')(0, 0, self.宽度, self.高度)
            end
        end
    else
        self._spr = nil
    end
    return self
end

function GUI控件:取精灵()
    return self._spr
end

function GUI控件:取父控件()
    return self.父控件
end

function GUI控件:取根控件()
    if not self.父控件.取根控件 then
        return self.父控件
    end
    return self.父控件:取根控件()
end

function GUI控件:取窗口()
    if not self.父控件.取窗口 then
        return self.父控件
    end
    return self.父控件:取窗口()
end

function GUI控件:绝对可见()
    if self.是否可见 then
        return true
    end
    if self.父控件.绝对可见 then
        return self.父控件:绝对可见()
    end
end

function GUI控件:置坐标(x, y) --坐标是相对于父的
    self.x = x or 0
    self.y = y or 0
    self.矩形:置坐标(self:取坐标())
    return self
end

function GUI控件:取坐标()
    local x, y = self.x, self.y

    if x < 0 then --如果坐标为负数，则值相对于 宽高 - 坐标
        if self.父控件 and self.父控件.宽度 then
            x = x + self.父控件.宽度
        end
    end
    if y < 0 then
        if self.父控件 and self.父控件.高度 then
            y = y + self.父控件.高度
        end
    end

    if self._hx and self._hy then
        x = x + self._hx --中心
        y = y + self._hy
    end

    if self.父控件 and self.父控件.取坐标 then
        local px, py = self.父控件:取坐标()
        return x + px, y + py
    end
    return x, y
end

function GUI控件:置中心(x, y)
    self._hx = math.floor(x) or 0
    self._hy = math.floor(y) or 0
    self.矩形:置坐标(self:取坐标())
    return self
end

function GUI控件:取中心()
    return self._hx, self._hy
end

function GUI控件:置宽高(w, h)
    self.宽度 = w
    self.高度 = h
    self.矩形:置宽高(w, h)
    return self
end

function GUI控件:取宽高()
    return self.宽度, self.高度
end

function GUI控件:取坐标宽高()
    local x, y = self:取坐标()
    return x, y, self.宽度, self.高度
end

function GUI控件:置宽度(w)
    self.宽度 = w
    self.矩形:置宽高(w, self.高度)
    return self
end

function GUI控件:置高度(h)
    self.高度 = h
    self.矩形:置宽高(self.宽度, h)
    return self
end

function GUI控件:取文字()
    return self._文字
end

function GUI控件:遍历控件()
    local 子控件 = {}
    for i, v in ipairs(self.子控件) do
        子控件[i] = v
    end
    return next, 子控件
end

function GUI控件:置检查区域(x, y, w, h)
    self.矩形:置中心(-x, -y)
    self.矩形:置宽高(w, h)
    return self
end

function GUI控件:检查点(x, y)
    if self.父控件.检查点 then
        return self.父控件:检查点(x, y) and self.矩形:检查点(x, y)
    end
    return self.矩形:检查点(x, y)
end

function GUI控件:检查透明(x, y)
    if self._spr and type(self._spr.取透明) == 'function' then
        return self._spr:取透明(x, y) > 0
    end
    return false
end

function GUI控件:置可见(val, sub)
    if val and self.是否实例 and self.是否禁止 then
        return self
    end
    if self._lock then
        self.是否可见 = val == true
        return self
    end
    self._lock = true
    if self:发送消息('可见事件', val) == false then
        return self
    end
    self.是否可见 = val == true

    if not self.是否实例 and val then
        if rawget(self, '初始化') then
            ggexpcall(self.初始化, self)
        end
        self.是否实例 = true
    end
    if sub then
        for _, v in ipairs(self.子控件) do
            v:置可见(val, sub)
        end
    end
    self._lock = nil
    return self
end

function GUI控件:重新初始化(...)
    if self.是否实例 then
        if rawget(self, '初始化') then
            ggexpcall(self.初始化, self, ...)
        end
    end
    for _, v in ipairs(self.子控件) do
        v:重新初始化(...)
    end
end

function GUI控件:置禁止(v)
    self.是否禁止 = v == true
    return self
end

function GUI控件:注册事件(k, v)
    if not self._reg then
        self._reg = setmetatable({}, {__mode = 'k'}) --注册消息
    end
    self._reg[k] = v
end

function GUI控件:发送消息(name, ...)
    if self._reg then
        for k, v in pairs(self._reg) do
            if v[name] then
                coroutine.xpcall(v[name], self, ...)
            end
        end
    end

    local fun = rawget(self, name)
    if type(fun) == 'function' then
        return coroutine.xpcall(fun, self, ...)
    end
end

function GUI控件:释放()
    for i, v in ipairs(self.子控件) do
        v:释放()
        self[v.名称] = nil
        --释放引用(v)
    end
    self.子控件 = {}
end

function GUI控件:清空消息(msg)
    if msg.鼠标 then
        for _, v in ipairs(msg.鼠标) do
            v.x = -9999
            v.y = -9999
        end
    end
end

function GUI控件:删除控件(name)
    if name then
        local 控件 = self[name]
        if 控件 then
            for i, v in ipairs(self.子控件) do
                if v == 控件 then
                    table.remove(self.子控件, i)
                    break
                end
            end
            self[name] = nil
        end
    else
        for i, v in ipairs(self.子控件) do
            self[v.名称] = nil
        end
        self.子控件 = {}
    end
end

function GUI控件:取子控件数量()
    return #self.子控件
end

function GUI控件:创建控件(name, x, y, w, h)
    assert(not self[name], name .. ':此控件已存在，不能重复创建.')
    self[name] = GUI控件(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end
--===========================================================================
local GUI弹出控件 = class('GUI弹出控件', GUI控件)

function GUI弹出控件:置可见(b, s)
    if not self.是否可见 then
        table.insert(self:取根控件()._popup, self)
    end
    GUI控件.置可见(self, b, s or not self.是否实例)
    return self
end

function GUI控件:创建弹出控件(name, x, y, w, h)
    return GUI弹出控件(name, x, y, w, h, self)
end

--===========================================================================
local GUI提示控件 = class('GUI提示控件', GUI控件)

function GUI提示控件:置可见(b, s)
    local _tip = self:取根控件()._tip
    if b then
        if not _tip[self] then
            table.insert(_tip, self)
            _tip[self] = self
        end
    else
        _tip[self] = nil
    end
    GUI控件.置可见(self, b, s or not self.是否实例)
    return self
end

function GUI控件:创建提示控件(name, x, y, w, h)
    return GUI提示控件(name, x, y, w, h, self)
end
return GUI控件
