-- @Author: baidwwy
-- @Date:   2021-07-10 16:32:33
-- @Last Modified by: baidwwy
-- @Last Modified time: 2022-01-09 05:30:19

local gge = require('ggelua')
local SDL = require 'SDL'
--===================================================================
local SDL精灵 = require('SDL.精灵')
local 输入光标 = class('GUI输入光标', SDL精灵)
function 输入光标:初始化(对象)
    SDL精灵.SDL精灵(self, 0, 0, 0, 1, 15)
    self:置颜色(0, 0, 0, 255)
    self.对象 = 对象
    self.计时 = 0
    self.间隔 = 0.5
end

function 输入光标:更新(dt)
    if self.对象._输入焦点 then
        self.计时 = self.计时 + dt
        if self.计时 >= self.间隔 then
            self.计时 = 0
            self.可见 = not self.可见
        end
    end
end

function 输入光标:显示(x, y)
    if self.对象._输入焦点 and self.可见 then
        SDL精灵.显示(self, x, y)
    end
end
--===================================================================
local function _输入事件(self)
    if not self._lock then
        self._lock = true
        self:发送消息('输入事件')
        self._lock = false
    end
end

local function _更新精灵中心(self)
    local x, y = 0, 0
    for i, v in ipairs(self._内容) do
        local spr = self._精灵[i]

        if self._模式 & self.多行模式 == self.多行模式 then --自动换行
            if v ~= '\n' and x + spr.宽度 > self.宽度 then
                self._精灵[i - 1].ar = true
                y = y + self._行高
                x = 0
            end
        end

        spr:置中心(-x, -y)

        if v == '\n' then
            spr.nr = true
            y = y + self._行高
            x = 0
        else
            x = x + spr.宽度
        end
    end
end
local GUI控件 = require('GUI.控件')
--===================================================================
local GUI输入 = class('GUI输入', GUI控件)
GUI输入.英文模式 = 1
GUI输入.数字模式 = 2
GUI输入.小数模式 = 4
GUI输入.负数模式 = 8
GUI输入.符号模式 = 16
GUI输入.中文模式 = 32
GUI输入.正常模式 = 255

GUI输入.密码模式 = 256
GUI输入.多行模式 = 512

function GUI输入:初始化()
    self._root = self:取根控件()
    self._文字 = self._root._文字:复制():置颜色(0, 0, 0, 255)

    self._光标 = 输入光标(self)

    self._行高 = 14
    self._内容 = {''} --文本
    self._精灵 = {self._文字:取精灵('')} --精灵
    self._偏移x = 0 --单行时内容宽度超过输入框
    self._偏移y = 0 --多行时内容高度超过输入框
    self._光标位置 = 1

    self._限制字数 = 0

    self._输入焦点 = false

    self._密码符号 = '*'
    self._禁止内容 = {}
    self._模式 = self.正常模式
    self._选中颜色 = {0, 120, 215, 255}
end

function GUI输入:_更新(...)
    self._光标:更新(...)
    GUI控件._更新(self, ...)
end

function GUI输入:_显示(...)
    local _x, _y = self:取坐标()

    if self._win:置区域(_x, _y, self.宽度, self.高度) then
        self:_后显示(_x, _y, ...)
        if self._精灵 == 1 and self._提示文本 then
            self._提示文本:显示(_x, _y)
            self._光标:显示(_x, _y)
        else
            for i, v in ipairs(self._精灵) do
                if v.选中 then
                    v.选中:显示(_x + self._偏移x, _y + self._偏移y)
                end
                v:显示(_x + self._偏移x, _y + self._偏移y)
                if i == self._光标位置 then --光标显示
                    self._光标:显示(v:取坐标())
                end
            end
        end

        --内容偏移
        if self._cp ~= self._光标位置 then
            local i = self._光标位置
            self._cp = i
            if self._模式 & self.多行模式 == self.多行模式 then
                --TODO
            else
                if i == 1 then
                    self._偏移x = 0
                elseif i == #self._精灵 then
                    local x1 = self._精灵[1]:取坐标()
                    local v = self._精灵[#self._精灵]
                    local x = v:取坐标()
                    if x > _x + self.宽度 or self._偏移x < 0 then
                        self._偏移x = -(x - x1 - self.宽度)
                    end
                elseif self._精灵[i] then
                    local x = self._精灵[i]:取坐标()
                    if x > _x + self.宽度 then --向右
                        self._偏移x = self._偏移x + (_x + self.宽度) - x
                    elseif x < _x then
                        self._偏移x = self._偏移x + (_x - x)
                    end
                end
                if self._偏移x > 0 then
                    self._偏移x = 0
                end
            end
        end
        self:_前显示(_x, _y, ...)
        self._win:置区域()
    end
end
--===========================================================================
--配置相关
--===========================================================================
function GUI输入:置颜色(...)
    self._文字:置颜色(...)
    self._光标:置颜色(...)
    return self
end

function GUI输入:取文字()
    return self._文字
end

function GUI输入:置文字(f, ...)
    if ggetype(f) == 'SDL文字' then
        self._文字 = f
    else
        self._文字 = require('SDL.文字')(f, ...)
    end
    return self
end

function GUI输入:置光标精灵(v)
    if type(v) == 'table' and v.更新 and v.显示 then
        self._光标 = v
    end
    return self
end

function GUI输入:取光标精灵()
    return self._光标
end

function GUI输入:置光标颜色(...)
    self._光标:置颜色(...)
    return self
end

function GUI输入:置选中颜色(...)
    self._选中颜色 = {...}
    return self
end

function GUI输入:置提示文本(str, r, g, b, a)
    local t
    if r and g and b then
        t = {self._文字:取颜色()}
        self._文字:置颜色(r, g, b, a)
    end
    self._提示文本 = self._文字:取精灵(str)
    if t then
        self._文字:置颜色(table.unpack(t))
    end
    return self
end

function GUI输入:置模式(v, 符号)
    if type(v) == 'number' then
        self._模式 = v
    end

    if 符号 then
        self._密码符号 = 符号
    end
    return self
end

function GUI输入:置限制字数(v)
    self._限制字数 = v
    return self
end

--===========================================================================
--内容相关
--===========================================================================
function GUI输入:清空()
    self._内容 = {''} --文本
    self._精灵 = {self._文字:取精灵('')} --精灵
    self._光标位置 = 1
    self._偏移x = 0 --单行时内容宽度超过输入框
    self._偏移y = 0 --多行时内容高度超过输入框
    self._选中起始 = nil
    self._选中结束 = nil
end

local adler32 = require('zlib').adler32
function GUI输入:添加对象(str, obj)
    if type(str) == 'string' then
        local pos = self._光标位置
        local spr = self._文字:取精灵(str)
        spr.对象 = obj
        local 标识 = string.format('［%X］', adler32(tostring(obj)))
        table.insert(self._内容, pos, 标识)
        table.insert(self._精灵, pos, spr)
        self._光标位置 = pos + 1
        _更新精灵中心(self)
        return 标识
    end
end

function GUI输入:取对象(i)
    local r = {}
    for i, v in ipairs(self._精灵) do
        if v.对象 then
            table.insert(r, v.对象)
        end
    end
    return r
end

local function _检查输入内容(self, c, v)
    if not c then
        return false
    end
    local b = string.byte

    if c >= b '0' and c <= b '9' then
        return self._模式 & self.数字模式 == self.数字模式
    elseif c >= b 'A' and c <= b 'Z' then --大字字母
        return self._模式 & self.英文模式 == self.英文模式
    elseif c >= b 'a' and c <= b 'z' then --小字字母
        return self._模式 & self.英文模式 == self.英文模式
    elseif c == b '.' then --小数点
        return self._模式 & self.小数模式 == self.小数模式
    elseif c == b '-' then --负号
        return self._模式 & self.负数模式 == self.负数模式
    elseif #v == 1 then
        return self._模式 & self.符号模式 == self.符号模式
    elseif #v >= 3 then
        return self._模式 & self.中文模式 == self.中文模式
    end

    return false
end

function GUI输入:插入文本(str, p, 光标)
    if type(str) == 'string' then
        str = str:gsub('\r\n', '\n')
        str = str:gsub('\r', '')
        --检查输入
        local lstr = {}
        for _, c in utf8.codes(str) do
            local v = utf8.char(c)
            if _检查输入内容(self, c, v) then
                if v ~= '\n' or self._模式 & self.多行模式 == self.多行模式 then
                    table.insert(lstr, v)
                end
            else
                return false
            end
        end

        self:删除选中()

        local pos = self._光标位置
        local len = 0
        for i, v in ipairs(lstr) do
            if self._限制字数 > 0 then
                if #self._内容 > self._限制字数 then
                    if i == 1 then
                        return false
                    else
                        break
                    end
                end
            end

            table.insert(self._内容, pos, v)
            if self._模式 & self.密码模式 == self.密码模式 then
                table.insert(self._精灵, pos, self._文字:取精灵(self._密码符号))
            else
                table.insert(self._精灵, pos, self._文字:取精灵(v))
            end

            pos = pos + 1
        end
        self._光标位置 = pos
        _更新精灵中心(self)
        _输入事件(self)

        return true
    end
end

GUI输入.添加文本 = GUI输入.插入文本
function GUI输入:置文本(v)
    self:清空()
    self:添加文本(tostring(v))
    return self
end

function GUI输入:置数值(v)
    if type(v) == 'number' then
        self:置文本(tostring(v))
    end
end

function GUI输入:取文本()
    local str = table.concat(self._内容) or ''
    return (str:gsub('\n', '\r\n'))
end

function GUI输入:取数值()
    return tonumber(self:取文本()) or 0
end

function GUI输入:取内容()
    if self._模式 ~= self.正常模式 and self._模式 & self.数字模式 == self.数字模式 then
        return self:取数值()
    end
    return self:取文本()
end
--===========================================================================
--控制相关
--===========================================================================

function GUI输入:置焦点(v)
    if self._输入焦点 ~= v then
        self._输入焦点 = v
        self._光标.可见 = true
        self._光标.x = 0 --更新输入法位置
        if v then
            if self._root._输入焦点 and self._root._输入焦点 ~= self then
                self._root._输入焦点:置焦点(false)
            end
            self._root._输入焦点 = self --外部调用
            self:发送消息('获得输入焦点')
        else
            self:取消选中()
            self:发送消息('失去输入焦点')
        end
    end
    return self
end

function GUI输入:置禁止(v)
    self.是否禁止 = v
    self._输入焦点 = false
    return self
end

function GUI输入:是否选中()
    return self._选中起始 ~= nil
end

function GUI输入:删除选中()
    if self:是否选中() then
        for i = 1, self._选中结束 - self._选中起始 do
            table.remove(self._内容, self._选中起始)
            table.remove(self._精灵, self._选中起始)
        end
        self._光标位置 = self._选中起始
        self._选中起始 = nil
        self._选中结束 = nil
        _更新精灵中心(self)
        _输入事件(self)
        return true
    end
end

function GUI输入:取消选中()
    if self:是否选中() then
        self._选中起始 = nil
        self._选中结束 = nil
        for i, v in ipairs(self._精灵) do
            v.选中 = nil
        end
    end
    return self
end

function GUI输入:全部选中()
    self._选中起始 = 1
    self._选中结束 = #self._精灵
    for _, v in ipairs(self._精灵) do
        v.选中 = require('SDL.精灵')(0, 0, 0, v.宽度, v.高度):置颜色(table.unpack(self._选中颜色)):置中心(v:取中心())
    end
    return self
end

function GUI输入:取选中文本()
    if self:是否选中() then
        local str = table.concat(self._内容, '', self._选中起始, self._选中结束)
        return (str:gsub('\n', '\r\n'))
    end
    return ''
end

--===========================================================================
local function _计算光标位置(self, mx, my)
    self._光标.可见 = true
    if self._模式 & self.多行模式 == self.多行模式 then
        for i, v in ipairs(self._精灵) do
            local x, y = v:取坐标()
            local w = v.宽度 / 2

            if y + self._行高 > my then
                if x + w > mx or v.nr then --nr符号折行
                    self._光标位置 = i
                    return
                elseif v.ar then --ar自动折行
                    self._光标位置 = i + 1
                    return
                end
            end
        end
    else
        local v = self._精灵[1]
        local x1 = v:取坐标()
        if mx <= x1 then
            self._光标位置 = 1
            return
        end
        local v = self._精灵[#self._精灵]
        local x = v:取坐标()
        if mx >= x then
            self._光标位置 = #self._精灵
            return
        end
        for i, v in ipairs(self._精灵) do
            local x = v:取坐标()
            local w = v.宽度 / 2

            if x + w > mx then
                self._光标位置 = i
                return
            end
        end
    end
    self._光标位置 = #self._精灵
end

local function _计算选中区域(self)
    local min = math.min(self._按下位置, self._光标位置)
    local max = math.max(self._按下位置, self._光标位置)
    self._选中起始 = min
    self._选中结束 = max
    for i, v in ipairs(self._精灵) do
        if i >= min and i < max then
            v.选中 = require('SDL.精灵')(0, 0, 0, v.宽度, v.高度):置颜色(table.unpack(self._选中颜色)):置中心(v:取中心())
        else
            v.选中 = nil
        end
    end
end
--===========================================================================
function GUI输入:_消息事件(msg)
    if not self.是否可见 or self.是否禁止 then
        return
    end

    if self._输入焦点 then
        if msg.父窗口可见 == false then
            if self._输入焦点 then
                if gge.platform == 'Android' or gge.platform == 'iOS' then
                    SDL.StopTextInput()
                else
                    local def = self:取根控件():取默认输入()
                    if def then
                        def:置焦点(true)
                    end
                end
            end
        end

        if msg.输入 then
            for _, v in ipairs(msg.输入) do
                self._光标.可见 = true
                self:插入文本(v.text)
            end
        end

        if msg.输入法 then
            for _, v in ipairs(msg.输入法) do
                --print(#v.text,v.text,v.start,v.length)--TODO
            end
        end
    end

    if msg.鼠标 then
        for _, v in ipairs(msg.鼠标) do
            if v.type == SDL.MOUSE_DOWN then
                if v.button == SDL.BUTTON_LEFT then
                    self._按下位置 = nil
                    if self:检查点(v.x, v.y) then
                        v.typed, v.type = v.type, nil
                        v.control = self
                        self._按下位置 = self._光标位置
                        self._左键按下 = true
                        
                        _计算光标位置(self, v.x, v.y)
                    else
                        self:取消选中()
                    end
                end
            elseif v.type == SDL.MOUSE_UP then
                if v.button == SDL.BUTTON_LEFT and self._左键按下 then
                    if self:检查点(v.x, v.y) then
                        v.typed, v.type = v.type, nil
                        v.control = self

                        if self._光标位置 == self._按下位置 then
                            self:取消选中()
                        end
                        if v.clicks == 2 and self._cxy and v.x == self._cxy.x and v.y == self._cxy.y then --双击全选
                            self:全部选中()
                        end
                        self._cxy = {x = v.x, y = v.y}

                        self:置焦点(true)
                        local x, y = 引擎:取实际坐标(self:取坐标()) --因为这个坐标是缩放的，转成实际的，才能适应软键盘高度
                        SDL.SetTextInputRect(x, y + self.高度, self.宽度, self.高度)
                        if gge.platform == 'Android' or gge.platform == 'iOS' then
                            if v then
                                SDL.StartTextInput()
                            end
                        end
                    elseif not self._左键按下 then
                        self:置焦点(false)
                    end
                    self._左键按下 = nil
                end
            elseif v.type == SDL.MOUSE_MOTION then --拖选
                if self:检查点(v.x, v.y) then
                    self._focus = true
                    local x, y = self:取坐标()
                    if self:发送消息('获得鼠标', x, y, msg) then
                        v.typed, v.type = v.type, nil
                        v.control = self
                    end
                elseif self._focus then
                    self._focus = nil
                    self:发送消息('失去鼠标', v.x, v.y, msg)
                end

                if self._按下位置 and v.state == SDL.BUTTON_LMASK then --左键按住
                    v.type = nil
                    _计算光标位置(self, v.x, v.y)
                    _计算选中区域(self)
                end
            end
        end
    end

    if not self._输入焦点 or self.是否禁止 or not msg.键盘 then
        return
    end

    for _, v in ipairs(msg.键盘) do
        if self:发送消息('键盘事件', table.unpack(v)) then --键码（SDL.KEY_？）,功能键（SDL.KMOD_？）,状态（按下，弹起）,按住
            v[1] = nil --清除键码
            v.keysym.sym = nil
        end
        if not v.state and (v.keysym.sym == SDL.KEY_ENTER or v.keysym.sym == SDL.KEY_KP_ENTER) then --回车
            v[1] = nil
            if self._模式 & self.多行模式 == self.多行模式 then
                self._光标.可见 = true
                self:插入文本('\n')
            end
        end
        if v.state then --按下
            if v.keysym.mod & SDL.KMOD_CTRL ~= 0 then
                if v.keysym.sym == SDL.KEY_C then --复制
                    if self:是否选中() then
                        SDL.SetClipboardText(self:取选中文本())
                    end
                elseif v.keysym.sym == SDL.KEY_A then --全选
                    self:全部选中()
                elseif v.keysym.sym == SDL.KEY_V then --粘贴
                    if SDL.HasClipboardText() then
                        self:删除选中()
                        self:插入文本(SDL.GetClipboardText())
                    end
                elseif v.keysym.sym == SDL.KEY_X then --剪贴
                    if self:是否选中() then
                        SDL.SetClipboardText(self:取选中文本())
                        self:删除选中()
                    end
                elseif v.keysym.sym == SDL.KEY_Z then --撤消
                --TODO
                end
            elseif v.keysym.mod & SDL.KMOD_SHIFT ~= 0 then
                if v.keysym.sym == SDL.KEY_LEFT then --左选中
                    if self._按下位置 then
                        if self._光标位置 > 1 then
                            self._光标位置 = self._光标位置 - 1
                        end
                    else
                        self._按下位置 = self._光标位置
                        self._光标位置 = self._光标位置 - 1
                    end
                    if self._光标位置 == self._按下位置 then
                        self:取消选中()
                    end
                    _计算选中区域(self)
                elseif v.keysym.sym == SDL.KEY_RIGHT then --右选中
                    if self._按下位置 then
                        if self._光标位置 < #self._内容 then
                            self._光标位置 = self._光标位置 + 1
                        end
                    else
                        self._按下位置 = self._光标位置
                        self._光标位置 = self._光标位置 + 1
                    end
                    if self._光标位置 == self._按下位置 then
                        self:取消选中()
                    end
                    _计算选中区域(self)
                elseif v.keysym.sym == SDL.KEY_UP then --上选中
                    --TODO
                elseif v.keysym.sym == SDL.KEY_DOWN then --下选中
                    --TODO
                elseif v.keysym.sym == SDL.KEY_HOME then --选中最左
                    self._按下位置 = self._光标位置
                    self._光标位置 = 1
                    _计算选中区域(self)
                elseif v.keysym.sym == SDL.KEY_END then --选中最右
                    self._按下位置 = self._光标位置
                    self._光标位置 = #self._内容
                    _计算选中区域(self)
                end
            elseif v.keysym.sym == SDL.KEY_BACKSPACE then --退格
                if not self:删除选中() then
                    if self._光标位置 > 1 then
                        table.remove(self._内容, self._光标位置 - 1)
                        table.remove(self._精灵, self._光标位置 - 1)
                        self._光标位置 = self._光标位置 - 1
                        self._光标.可见 = true
                        _更新精灵中心(self)
                        _输入事件(self)
                    end
                end
            elseif v.keysym.sym == SDL.KEY_LEFT then --左移动
                if self:是否选中() then
                    if self._按下位置 < self._光标位置 then
                        self._光标位置 = self._按下位置
                    end
                    self:取消选中()
                elseif self._光标位置 > 1 then
                    self._光标位置 = self._光标位置 - 1
                end
                self._光标.可见 = true
                self._按下位置 = nil
            elseif v.keysym.sym == SDL.KEY_RIGHT then --右移动
                if self:是否选中() then
                    if self._按下位置 > self._光标位置 then
                        self._光标位置 = self._按下位置
                    end
                    self:取消选中()
                elseif self._光标位置 < #self._内容 then
                    self._光标位置 = self._光标位置 + 1
                end
                self._光标.可见 = true
                self._按下位置 = nil
            elseif v.keysym.sym == SDL.KEY_HOME then --移动最左
                self:取消选中()
                self._光标位置 = 1
                self._光标.可见 = true
                self._按下位置 = nil
            elseif v.keysym.sym == SDL.KEY_END then --移动最右
                self:取消选中()
                self._光标位置 = #self._内容
                self._光标.可见 = true
                self._按下位置 = nil
            end
        end
    end
end

local _输入列表 = {}
function GUI控件:创建输入(name, x, y, w, h)
    assert(not (self[name] or _输入列表[name]), name .. ':此输入已存在，不能重复创建.')
    local v = GUI输入(name, x, y, w, h, self)
    self[name] = v
    table.insert(self.子控件, v)
    --_输入列表[name] = v
    return v
end

function GUI控件:创建编辑(name, x, y, w, h)
    assert(not (self[name] or _输入列表[name]), name .. ':此编辑已存在，不能重复创建.')
    local v = GUI输入(name, x, y, w, h, self)
    self[name] = v
    table.insert(self.子控件, v)
    --_输入列表[name] = v
    v:置模式(v.正常模式 | v.多行模式)
    return v
end
return GUI输入
