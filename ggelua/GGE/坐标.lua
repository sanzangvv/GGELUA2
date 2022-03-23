-- @Author       : GGELUA
-- @Date         : 2021-09-17 08:26:43
-- @Last Modified by    : GGELUA
-- @Last Modified time  : 2022-03-23 13:17:47

local GGE坐标 = class 'GGE坐标'
GGE坐标.x = 0
GGE坐标.y = 0
function GGE坐标:GGE坐标(x, y)
    if type(x) == 'table' then
        self.x = x.x or x[1] or 0
        self.y = x.y or x[2] or 0
    else
        self.x = tonumber(x)
        self.y = tonumber(y)
    end
end

function GGE坐标:ceil()
    self.x = math.ceil(self.x)
    self.y = math.ceil(self.y)
    return self
end

function GGE坐标:floor()
    self.x = math.floor(self.x)
    self.y = math.floor(self.y)
    return self
end

function GGE坐标:unpack()
    return self.x, self.y
end

function GGE坐标:pack(x, y)
    if type(x) == 'number' and type(y) == 'number' then
        self.x = x
        self.y = y
    elseif ggetype(x) == 'GGE坐标' then
        self.x = x.x
        self.y = x.y
    end
    return self:floor()
end

function GGE坐标:四舍五入()
    self.x = self.x < 0 and self.x - 0.5 or self.x + 0.5
    self.y = self.y < 0 and self.y - 0.5 or self.y + 0.5
    return self:floor()
end

function GGE坐标:复制(x, y)
    local r = GGE坐标(self.x, self.y)
    return x and r:增加(x, y) or r
end

function GGE坐标:随机加(x, x1, y, y1)
    local x = math.random(x, x1)
    local y = math.random(y or x, y1 or x1)
    self:增加(x, y)
    return self
end

function GGE坐标:增加(x, y)
    self.x = self.x + (x or 0)
    self.y = self.y + (y or 0)
    return self
end

function GGE坐标:随机(x, x1, y, y1)
    self.x = math.random(x, x1)
    self.y = math.random(y or x, y1 or x1)
    return self
end
--取两点距离
function GGE坐标:取距离(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    x = self.x - x
    y = self.y - y
    return math.sqrt((x ^ 2) + (y ^ 2)) --平方根
end
--取两点弧度
local math_pi2 = math.pi * 2
function GGE坐标:取弧度(_x, _y)
    if not _y and ggetype(_x) == 'GGE坐标' then
        _x, _y = _x:unpack()
    end
    local x, y = self.x, self.y

    if _y == y and _x == x then
        return 0
    elseif _y >= y and _x <= x then
        return math.pi - math.abs(math.atan((_y - y) / (_x - x)))
    elseif _y <= y and _x >= x then
        return math_pi2 - math.abs(math.atan((_y - y) / (_x - x)))
    elseif _y <= y and _x <= x then
        return math.atan((_y - y) / (_x - x)) + math.pi
    elseif _y >= y and _x >= x then
        return math.atan((_y - y) / (_x - x))
    end
end

function GGE坐标:取角度(x, y) --math.rad
    return math.deg(self:取弧度(x, y))
end

function GGE坐标:取地图位置(w, h) --图块宽高
    return GGE坐标(math.ceil(self.x / w), math.ceil(self.y / h))
end

function GGE坐标:取距离坐标(r, a) --距离,弧度
    -- if ggetype(a)=='GGE坐标' then
    --     a = self:取弧度(a)
    -- end
    local x, y = 0, 0
    x = r * math.cos(a) + self.x
    y = r * math.sin(a) + self.y
    return GGE坐标(x, y):四舍五入()
end

function GGE坐标:取移动坐标(r, x, y) --距离,目标点
    local a = self:取弧度(x, y)
    return self:取距离坐标(r, a)
end

function GGE坐标:移动(r, x, y) --距离,目标点
    local a = self:取弧度(x, y)
    self.x = r * math.cos(a) + self.x
    self.y = r * math.sin(a) + self.y
    return self:四舍五入()
end
--宽度2 = 宽度//2
function GGE坐标:取地图偏移(w, h) --地图宽高
    local _x, _y = 0, 0
    local x, y = self.x, self.y
    if w > 引擎.宽度 then --地图小于窗口
        if x > 引擎.宽度2 and x < w - 引擎.宽度2 then
            _x = -(x - 引擎.宽度2)
        elseif x <= 引擎.宽度2 then
            _x = 0
        elseif x >= w - 引擎.宽度2 then
            _x = -(w - 引擎.宽度)
        end
    end
    if h > 引擎.高度 then
        if y > 引擎.高度2 and y < h - 引擎.高度2 then
            _y = -(y - 引擎.高度2)
        elseif y <= 引擎.高度2 then
            _y = 0
        elseif y >= h - 引擎.高度2 then
            _y = -(h - 引擎.高度)
        end
    end
    return GGE坐标(_x, _y)
end

function GGE坐标:画线(x, y, r, g, b, a)
    if ggetype(x) == 'GGE坐标' then
        color = y
        x, y = x:unpack()
    end
    引擎:置颜色(r, g, b, a)
    引擎:画线(self.x, self.y, x, y)
    return self
end

function GGE坐标:显示(r, g, b, a)
    local angle = 360 / 20
    引擎:置颜色(255, 0, 0, 255)
    for i = 0, 20 - 1 do
        local pxy = self:取距离坐标(3, math.rad(i * angle)) --rad角度转弧度
        local pxy1 = self:取距离坐标(3, math.rad((i + 1) * angle))
        引擎:画线(pxy.x, pxy.y, pxy1.x, pxy1.y)
    end
    return self
end

--==============================================================================
--元方法(重载)
--==============================================================================
--等于 ==
function GGE坐标.__eq(a, b)
    return a.x == b.x and a.y == b.y
end
--小于 <
function GGE坐标.__lt(a, b)
    return a.x < b.x and a.y < b.y
end
--小于等于 <=
function GGE坐标.__le(a, b)
    return a.x <= b.x and a.y <= b.y
end
--相加 +
function GGE坐标.__add(a, b)
    if ggetype(a) == 'GGE坐标' and ggetype(b) == 'GGE坐标' then
        return GGE坐标(a.x + b.x, a.y + b.y)
    elseif type(a) == 'number' then
        return GGE坐标(a + b.x, a + b.y)
    elseif type(b) == 'number' then
        return GGE坐标(a.x + b, a.y + b)
    end
end
--相减 -
function GGE坐标.__sub(a, b)
    if ggetype(a) == 'GGE坐标' and ggetype(b) == 'GGE坐标' then
        return GGE坐标(a.x - b.x, a.y - b.y)
    elseif type(a) == 'number' then
        return GGE坐标(a - b.x, a - b.y)
    elseif type(b) == 'number' then
        return GGE坐标(a.x - b, a.y - b)
    end
end
--相乘 *
function GGE坐标.__mul(a, b)
    if ggetype(a) == 'GGE坐标' and ggetype(b) == 'GGE坐标' then
        return GGE坐标(a.x * b.x, a.y * b.y)
    elseif type(a) == 'number' then
        return GGE坐标(a * b.x, a * b.y)
    elseif type(b) == 'number' then
        return GGE坐标(a.x * b, a.y * b)
    end
end
--相除 /
function GGE坐标.__div(a, b)
    if ggetype(a) == 'GGE坐标' and ggetype(b) == 'GGE坐标' then
        return GGE坐标(a.x / b.x, a.y / b.y)
    elseif type(a) == 'number' then
        return GGE坐标(a / b.x, a / b.y)
    elseif type(b) == 'number' then
        return GGE坐标(a.x / b, a.y / b)
    end
end
--整除 //
function GGE坐标.__idiv(a, b)
    if ggetype(a) == 'GGE坐标' and ggetype(b) == 'GGE坐标' then
        return GGE坐标(a.x // b.x, a.y // b.y)
    elseif type(a) == 'number' then
        return GGE坐标(a // b.x, a // b.y)
    elseif type(b) == 'number' then
        return GGE坐标(a.x // b, a.y // b)
    end
end

function GGE坐标.__tostring(self)
    return string.format('GGE.坐标(%s,%s)', self.x, self.y)
end

--__mod  %
--__pow ^
--__unm -
--__band &
--__bor |
--__bxor ~
--__bnot ~
--__shl <<
--__shr >>
--__concat ..
--__len #
--__index table[key]
--__newindex table[key] = value
--__call func(args)
--__gc
--__close
--__mode
--__name
return GGE坐标
