-- @Author: GGELUA
-- @Date:   2021-09-17 08:26:43
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-18 15:46:35

local SDL = require 'SDL'

local _objmeta = {
    检查点 = function(self, x, y)
        if self.rect then
            return self.rect:检查点(x, y)
        end
    end,
    置透明 = function(self, a)
        self.o:置透明(a)
    end,
    取坐标 = function(self)
        return self.o:取坐标()
    end,
    更新 = function(self, dt)
        if self.o.更新 then
            self.o:更新(dt)
        end
    end,
    显示 = function(self, x, y)
        if self.b then --闪烁
            self.b = self.b + 1
            if self.b > 60 then
                self.b = 0
            end
        end
        if not self.b or self.b > 30 then
            self.o:显示(self.x + x, y)
            if self.rect then
                self.rect:置坐标(self.o:取坐标())
            --self.rect:显示()
            end
        end
    end
}

local _obj = function(t, x, o)
    local self = setmetatable({}, {__index = _objmeta})
    self.x = x
    self.o = o --obj

    if t.m or t.url then
        self.cb = t.m or t.url
        self.rect = require('SDL.矩形')(0, 0, o.宽度, o.高度)
    end

    if t.b then --闪烁
        self.b = 0
    end
    return self
end
--==============================================================================
local _colors = { --RGBWYK
    [0x52] = 0xFF0000,
    [0x47] = 0x00FF00,
    [0x42] = 0x0000FF,
    [0x57] = 0xFFFFFF,
    [0x59] = 0xFFFF00,
    [0x4B] = 0x000000
}

local function _insert(t) --比table.insert 快
    local i = #t + 1
    return function(data)
        if data ~= nil then
            t[i] = data
            i = i + 1
        end
    end
end

local function _Parser(str) --解析结构
    local style_c, style_b, style_u, style_F, style_m  --颜色,下划线,闪烁,字体,回调
    local datas = {}
    local indata = _insert(datas)
    local codes = {}
    local incode = _insert(codes)

    local u8char = utf8.char
    local unpack = table.unpack
    local iter = utf8.codes(str)
    local p, code

    while true do
        p, code = iter(str, p)
        if not p then
            break
        end
        if code == 0x23 then --#?
            p, code = iter(str, p)
            if not p then
                break
            end
            if #codes >= 1 and code ~= 0x23 and code ~= 0x72 and not style_m then --结束
                indata {c = style_c, b = style_b, u = style_u, F = style_F, s = u8char(unpack(codes))}
                codes = {}
                incode = _insert(codes)
            end
            --样式解析
            if code == 0x23 then --##
                incode(code)
            elseif code == 0x62 then --#bXXXX#b 闪烁
                style_b = not style_b
            elseif code == 0x63 then --#cFFFFFF 指定16进制颜色
                style_c = tonumber(str:sub(p + 1, p + 6), 16)
                if style_c then
                    p = p + 6
                end
            elseif _colors[code] then --RGBWYK颜色
                style_c = _colors[code]
            elseif code == 0x6D then --#m(XXXX)XXXX#m 回调
                if style_m then
                    local m, s = string.match(u8char(unpack(codes)), '%((.+)%)(.*)')
                    indata {c = style_c, b = style_b, u = style_u, F = style_F, m = m, s = s}
                    codes = {}
                    incode = _insert(codes)
                end
                style_m = not style_m
            elseif code == 0x6E then --#n 结束
                style_c = nil
            elseif code == 0x75 then --#uXXXX#u 下划线
                style_u = not style_u
            elseif code == 0x72 then --#r 换行
                indata {c = style_c, b = style_b, u = style_u, F = style_F, r = true, s = u8char(unpack(codes))}
                codes = {}
                incode = _insert(codes)
            elseif code == 0x46 then --#FXXX14: 字体开始
                style_F = true
            elseif code >= 0x30 and code <= 0x39 then --#0 - #999 表情
                local num = {code}
                local p_ = p
                for i = 2, 3 do
                    p_, code = iter(str, p_)
                    if not code then
                        break
                    elseif code >= 0x30 and code <= 0x39 then
                        p = p_
                        num[i] = code
                    end
                end
                indata {s = tonumber(u8char(unpack(num)))}
            end
        elseif style_F == true and code == 0x3A then --: 字体结束
            local name, size = string.match(u8char(unpack(codes)), '([^%d]+)(%d*)')
            style_F = {name, tonumber(size)}
            codes = {}
            incode = _insert(codes)
        else --内容
            incode(code)
        end
    end

    if #codes > 0 then --结束
        indata {c = style_c, b = style_b, u = style_u, F = style_F, s = u8char(unpack(codes))}
    end

    return datas
end
--==============================================================================
--按宽度分折
local function _split(str, width, font)
    for i, c in utf8.codes(str) do
        local w = font:取宽度(utf8.char(c))
        if w > width then
            return str:sub(1, i - 1), str:sub(i)
        else
            width = width - w
        end
    end
    return '', str
end

--适应宽度，生成x坐标
local function _Adjust(self)
    local width = self.宽度
    local fonts = self._文字表
    local emote = self._精灵表

    local font = fonts.默认
    local fh = font:取高度()

    local ret = {}
    local x = 0
    line = {w = 0, h = fh}

    for _, v in ipairs(self._解析后) do
        if type(v.s) == 'string' then --文本
            --字体
            if type(v.F) == 'table' then
                local file, size = v.F[1], v.F[2]
                if fonts[file] then
                    font = fonts[file]
                end
                font:置大小(size)
                fh = size
                if not line.eh or fh > line.eh then --当没有表情时
                    line.h = fh
                end
            end
            --超链接
            local str = v.s
            if str:find('<url>') then
                str = str:match('<url>(.+)</url>')
                v.s = str
                v.url = str
                if str:find('<show>') then
                    local a, b = str:match('<show>(.+)</show>(.*)')
                    if a and b then
                        str = a
                        v.s = str
                        v.url = b
                    end
                end
            end
            --颜色
            if v.c then
                font:置颜色(v.c >> 16 & 0xFF, v.c >> 8 & 0xFF, v.c & 0xFF, 255)
            else
                font:置颜色(255, 255, 255, 255)
            end
            --下划线
            if v.u or v.url then
                font:置样式(SDL.TTF_STYLE_UNDERLINE)
            else
                font:置样式(font:取样式() & ~SDL.TTF_STYLE_UNDERLINE)
            end

            local w, h = font:取宽高(str)

            if x == 0 and w > 0 and font:取宽度(utf8.char(utf8.codepoint(str, 1))) > width then
                print('宽度过小')
            elseif x + w > width then --大于就换行
                ::loop::
                local a, b = _split(str, width - x, font)
                if a ~= '' then
                    w, h = font:取宽高(a)
                    table.insert(line, _obj(v, x, font:取精灵(a):置中心(0, h)))
                    x = x + w
                end
                line.w = x
                table.insert(ret, line)
                x = 0
                line = {w = 0, h = fh}
                 --换行

                w, h = font:取宽高(b)
                if w > width then --循环换行
                    str = b
                    goto loop
                else
                    table.insert(line, _obj(v, x, font:取精灵(b):置中心(0, h)))
                    x = x + w
                    if v.r or x == width then
                        line.w = x
                        table.insert(ret, line)
                        x = 0
                        line = {w = 0, h = fh}
                    end
                end
            else
                if w > 0 then
                    table.insert(line, _obj(v, x, font:取精灵(str):置中心(0, h)))
                    x = x + w
                end
                if v.r or x == width then
                    line.w = x
                    table.insert(ret, line)
                    x = 0
                    line = {w = 0, h = fh}
                end
            end
        elseif emote[v.s] then --表情
            local e = emote[v.s]
            if e then
                local w, h = e:取宽高()

                if x + w > width then --大于就换行
                    line.w = x
                    table.insert(ret, line) --换行
                    x = 0
                    line = {w = 0, h = fh}
                end
                if x + w <= width then
                    table.insert(line, _obj(v, x, e:复制()))
                    x = x + w
                end
                if h > line.h then
                    line.h = h
                    line.eh = h
                end
                if v.r or x == width then
                    line.w = x
                    table.insert(ret, line)
                    x = 0
                    line = {w = 0, h = fh}
                end
            else --表情不存在，以文本显示
            end
        end
    end
    line.w = x
    table.insert(ret, line)
    for i, v in ipairs(ret) do
        v.eh = nil
    end
    return ret
end

--==================================================================

local GGE文本 = class('GGE文本')

function GGE文本:GGE文本(w, h)
    self.行间距 = 2

    self.宽度 = w or 400
    self.高度 = h or 200

    self._文字表 = {}
    self._精灵表 = {}
    self._数据表 = {} --适应宽度后的数据
end

function GGE文本:置文字(f, ...)
    if ggetype(f) == 'SDL文字' then
        self._文字表.默认 = f
    else
        self._文字表.默认 = require('SDL.文字')(f, ...)
    end
    return self
end

function GGE文本:取文字(f)
    return self._文字表[f or '默认']
end

function GGE文本:添加文字(name, font) --宋体，SDL文字
    self._文字表[name] = font
    if not self._文字表.默认 then
        self._文字表.默认 = font
    end
    return self
end

function GGE文本:添加精灵(k, v)
    if type(v) == 'table' and v.取宽高 and v.显示 and v.复制 then
        self._精灵表[k] = v
    end
    return self
end

function GGE文本:取行数()
    return #self._数据表
end

function GGE文本:清空()
    self._数据表 = {}
    return self
end

function GGE文本:置文本(s, ...)
    if not self._文字表.默认 then
        return 0, 0
    end
    if select('#', ...) > 0 then
        s = s:format(...)
    end
    self:清空()

    s = s:gsub('\r\n', '#r'):gsub('\r', '#r'):gsub('\n', '#r')
    self._解析后 = _Parser(s)
    for _, v in ipairs(_Adjust(self)) do
        table.insert(self._数据表, v)
    end

    local w, h, y = 0, 0, 0
    for _, v in ipairs(self._数据表) do
        if v.w > w then
            w = v.w
        end
        h = h + v.h + self.行间距

        y = y + v.h
        v.y = y
        y = y + self.行间距
    end

    return w, h - self.行间距 --返回当前区域内容最大宽高
end

function GGE文本:置透明(a)
    for _, line in ipairs(self._数据表) do
        for _, v in ipairs(line) do
            v:置透明(a)
        end
    end
    return self
end

function GGE文本:置宽度(v)
    if self.宽度 ~= v then
        self.宽度 = v
        self:清空()
        for _, v in ipairs(_Adjust(self)) do
            table.insert(self._数据表, v)
        end
    end
    local w, h, y = 0, 0, 0
    for _, v in ipairs(self._数据表) do
        if v.w > w then
            w = v.w
        end
        h = h + v.h + self.行间距

        y = y + v.h
        v.y = y
        y = y + self.行间距
    end

    return w, h - self.行间距 --返回当前区域内容最大宽高
end

function GGE文本:更新(dt)
    for _, line in ipairs(self._数据表) do
        for _, v in ipairs(line) do
            v:更新(dt)
        end
    end
end

function GGE文本:显示(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end

    if self.hx then--中心
        x,y = x-self.hx,y-self.hy
    end
    
    for _, line in ipairs(self._数据表) do
        for _, v in ipairs(line) do
            v:显示(x, y + line.y)
        end
    end
end

function GGE文本:置中心(x,y)
    self.hx = x
    self.hy = y
    return self
end

function GGE文本:检查回调(x, y)
    for _, line in ipairs(self._数据表) do
        for _, v in ipairs(line) do
            if v:检查点(x, y) then
                return v.cb, v
            end
        end
    end
end

return GGE文本
