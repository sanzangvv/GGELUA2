-- @Author: baidwwy
-- @Date:   2021-02-11 11:49:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-23 11:17:54

local SDL = require('SDL')
local SDL矩形 = class 'SDL矩形'

function SDL矩形:SDL矩形(x, y, w, h)
    if ggetype(x) == 'SDL_Rect' then
        self._rect = x
    else
        self._rect = SDL.CreateRect(x, y, w, h)
        self._CR = 255
        self._CA = 255
    end
end

function SDL矩形:__index(k)
    local t = rawget(self, '_rect')
    return t and t[k]
end

function SDL矩形:__newindex(k, v)
    if k == 'x' or k == 'y' or k == 'w' or k == 'h' then
        self._rect[k] = v
    else
        rawset(self, k, v)
    end
end

function SDL矩形:__eq(t) --SDL_RectEquals
    local a, b = self._rect, t._rect
    return (a.x == b.x) and (a.y == b.y) and (a.w == b.w) and (a.h == b.h)
end

function SDL矩形:复制()
    return SDL矩形(self._rect:GetRect())
end

function SDL矩形:显示(x, y)
    if self._CR then
        引擎:置颜色(self._CR, self._CG, self._CB, self._CA)
    end
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if x and y then
        self:置坐标(x, y)
        引擎:画矩形(self._rect)
    else
        引擎:画矩形(self._rect)
    end
end

function SDL矩形:置颜色(r, g, b, a)
    self._CR, self._CG, self._CB, self._CA = r, g, b, a or 255
    return self
end

function SDL矩形:置中心(x, y)
    self._hx = x
    self._hy = y
    return self
end

function SDL矩形:取中心()
    return self._hx, self._hy
end

function SDL矩形:置宽高(w, h)
    self._rect:SetRectWH(w, h)
    return self
end

function SDL矩形:取宽高()
    return self._rect:GetRectWH()
end

function SDL矩形:置坐标(x, y)
    self._rect:SetRectXY(x, y)
    return self
end

function SDL矩形:取坐标()
    return self._rect:GetRectXY()
end

function SDL矩形:清空()
end

function SDL矩形:检查点(x, y) --SDL_PointInRect
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    local _x, _y = self._rect:GetRectXY() --self._rect.x,self._rect.y
    local _w, _h = self._rect:GetRectWH() --self._rect.w,self._rect.h
    if self._hx then
        _x = _x - self._hx
    end
    if self._hy then
        _y = _y - self._hy
    end
    return (x >= _x) and (x < _x + _w) and (y >= _y) and (y < _y + _h)
end

function SDL矩形:检查交集(t) --判断两个矩形是否相交。
    return self._rect:HasIntersection(t._rect)
end

function SDL矩形:取交集(t)
    local r = SDL矩形()
    if self._rect:HasIntersection(t._rect) then
        r._rect = self._rect:IntersectRect(t._rect)
    end
    return r
end

function SDL矩形:取并集(t)
    local r = SDL矩形()
    r._rect = self._rect:UnionRect(t._rect)
    return r
end
--EnclosePoints
--IntersectRectAndLine
function SDL矩形:取对象()
    return self._rect
end

return SDL矩形
