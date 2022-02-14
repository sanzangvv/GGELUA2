-- @Author: baidwwy
-- @Date:   2021-02-11 11:49:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-07 02:58:09

local GGE矩形 = class 'GGE矩形'

function GGE矩形:GGE矩形(x, y, w, h)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 0
    self.h = h or 0
end

function GGE矩形:__eq(t)
    local a, b = self, t
    return (a.x == b.x) and (a.y == b.y) and (a.w == b.w) and (a.h == b.h)
end

function GGE矩形:复制()
    return GGE矩形(self.x, self.y, self.w, self.h)
end

function GGE矩形:显示(x, y)
    if self.r then
        引擎:置颜色(self.r, self.g, self.b)
    end
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if x and y then
    end
end

function GGE矩形:置颜色(r, g, b)
    self.r, self.g, self.b = r, g, b
    return self
end

function GGE矩形:置中心(x, y)
    self._hx = x
    self._hy = y
    return self
end

function GGE矩形:取中心()
    return self._hx, self._hy
end

function GGE矩形:置宽高(w, h)
    self.w = w or 0
    self.h = h or 0
    return self
end

function GGE矩形:取宽高()
    return self.w, self.h
end

function GGE矩形:置坐标(x, y)
    self.x = x or 0
    self.y = y or 0
    return self
end

function GGE矩形:取坐标()
    return self.x, self.y
end

function GGE矩形:清空()
    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0
end

function GGE矩形:检查点(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    local _x, _y = self.x, self.y
    local _w, _h = self.w, self.h
    if self._hx then
        _x = _x - self._hx
    end
    if self._hy then
        _y = _y - self._hy
    end
    return (x >= _x) and (x < _x + _w) and (y >= _y) and (y < _y + _h)
end

function GGE矩形:检查交集(t)
end

function GGE矩形:取交集(t)
    local r = GGE矩形()

    return r
end

function GGE矩形:取并集(t)
    local r = GGE矩形()

    return r
end

return GGE矩形
