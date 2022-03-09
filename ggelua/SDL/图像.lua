-- @Author: GGELUA
-- @Date:   2021-09-19 06:42:20
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-09 14:52:22

local _ENV = require('SDL')
IMG_Init()
local _target = {}

local SDL图像 = class 'SDL图像'

function SDL图像:SDL图像(a, b, c, d)
    local tp = ggetype(a)
    if tp == 'number' then
        if type(b) == 'number' then
            self._sf = SDL.CreateRGBSurfaceWithFormat(a, b, c, d) --宽度，高度，位深，格式
        end
    elseif tp == 'string' then
        self._sf = assert(IMG.LoadARGB8888(a, b), SDL.GetError()) --文件,透明色
    elseif tp == 'SDL_Surface' then
        self._sf = a
    elseif tp == 'SDL_RWops' then
        self._sf = assert(IMG.LoadARGB8888_RW(a, b), SDL.GetError())
    elseif tp == 'SDL读写' then
        self._sf = assert(IMG.LoadARGB8888_RW(a:取对象(), b), SDL.GetError())
    end

    if self._sf then
        _sfs[self] = self._sf
        self._win = SDL._win
    else
        error(SDL.GetError())
    end
end

function SDL图像:__close() --即时释放
    if self._sf then
        self._sf:__close()
    end
end

function SDL图像:__index(key)
    if key == '宽度' then
        return self._sf and self._sf.w or 0
    elseif key == '高度' then
        return self._sf and self._sf.h or 0
    end
end

function SDL图像:取对象()
    return self._sf
end

function SDL图像:复制()
    return self._win:创建图像(self._sf:DuplicateSurface())
end

function SDL图像:置窗口(v)
    self._win = v
    return self
end

function SDL图像:显示(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if self._hx then --中心
        x, y = x - self._hx, y - self._hy
    end
    if _target[1] then
        local t = _target[1]
        t.rect:SetRectXY(x, y)
        self._sf:BlitSurface(self._rect, t.sf, t.rect)
    elseif self._win then
        self._x, self._y = x, y
        self._win:显示图像(self._sf, x, y, self._rect)
    end
    return self
end

function SDL图像:锁定()
    if self._sf then
        return self._sf:LockSurface()
    end
end

function SDL图像:解锁()
    return self._sf and self._sf:UnlockSurface()
end

function SDL图像:到灰度()
    self._sf:SurfaceToGrayscale()
    return self
end

function SDL图像:到精灵()
    return require('SDL.精灵')(self._sf):置中心(self._hx, self._hy)
end

function SDL图像:检查点(x, y)
    local _x, _y = self._x, self._y
    local _w, _h = self._sf.w, self._sf.h
    return (x >= _x) and (x < _x + _w) and (y >= _y) and (y < _y + _h)
end

function SDL图像:检查透明(x, y)
    return self:取像素(x, y) > 0
end

function SDL图像:取像素(x, y)
    return self._sf:GetSurfacePixel(x, y)
end

function SDL图像:置像素(x, y, r, g, b, a)
    self._sf:SetSurfacePixel(x, y, r, g, b, a)
    return self
end

function SDL图像:保存文件(file, tp, quality)
    if not tp or tp == 'BMP' then
        return self._sf:SaveBMP(file)
    elseif tp == 'PNG' then
        return self._sf:SavePNG(file)
    elseif tp == 'JPG' then
        return self._sf:SaveJPG(file, quality)
    end
end

function SDL图像:取透明色()
    return self._sf:GetColorKey()
end

function SDL图像:置透明(a)
    self._sf:SetSurfaceBlendMode(SDL.BLENDMODE_BLEND)
    self._sf:SetSurfaceAlphaMod(a)
    return self
end

function SDL图像:取透明()
    return self._sf:GetSurfaceBlendMode()
end

function SDL图像:置颜色(r, g, b, a)
    self._sf:SetSurfaceColorMod(r, g, b)
    if a then
        self:置透明(a)
    end
    return self
end

function SDL图像:取颜色()
    return self._sf:GetSurfaceColorMod()
end

function SDL图像:置混合(b)
    self._sf:SetSurfaceBlendMode(b)
    return self
end

function SDL图像:取混合()
    return self._sf:GetSurfaceBlendMode()
end

function SDL图像:置区域(x, y, w, h)
    if x and y and w and h then
        self._rect = SDL.CreateRect(x, y, w, h)
    else
        self._rect = nil
    end
    return self
end

function SDL图像:取区域()
    return self._rect
end

function SDL图像:置渲染区域(x, y, w, h)
    if x and y and w and h then
        self._sf:SetClipRect(SDL.CreateRect(x, y, w, h))
    else
        self._sf:SetClipRect()
    end
    return self
end

function SDL图像:取渲染区域()
    return self._sf:GetClipRect()
end

function SDL图像:复制区域(x, y, w, h)
    local sf = SDL图像(w, h)
    if sf:渲染清除() then
        self:置区域(x, y, w, h):显示(0, 0)
        sf:渲染结束()
    end
    return sf
end

function SDL图像:平铺(w, h)
    local sf = SDL图像(w, h)
    if sf:渲染清除() then
        for y = 0, h, self._sf.h do
            for x = 0, w, self._sf.w do
                self:显示(x, y)
            end
        end
        sf:渲染结束()
    end
    return sf
end

function SDL图像:拉伸(w, h, linear)
    local sf = SDL图像(w, h)
    local dst = sf:取对象()
    if linear then
        self._sf:SoftStretch(nil, dst, nil)
    else
        self._sf:SoftStretchLinear(nil, dst, nil)
    end
    return sf
end

function SDL图像:转换格式(format, flags)
    if type(format) == 'number' then
        return self._win:创建图像(self._sf:ConvertSurfaceFormat(format, flags))
    elseif ggetype(format) == 'SDL_PixelFormat' then
        return self._win:创建图像(self._sf:ConvertSurface(format, flags))
    end
end

function SDL图像:填充颜色(r, g, b, a)
    self._sf:FillRect(r, g, b, a)
    return self
end

function SDL图像:置中心(x, y)
    self._hx, self._hy = x and math.floor(x), y and math.floor(y)
    return self
end

function SDL图像:取中心()
    return self._hx, self._hy
end

function SDL图像:取引用()
    return self._sf.refcount
end

function SDL图像:加引用()
    local refcount = self._sf.refcount
    self._sf.SetSurfaceRef(refcount + 1)
    return refcount
end

function SDL图像:减引用()
    local refcount = self._sf.refcount
    if refcount > 1 then
        self._sf.SetSurfaceRef(refcount + 1)
    end
    return refcount
end

function SDL图像:渲染清除(r, g, b, a)
    if r then
        self._sf:FillRect(r, g, b, a)
    end
    table.insert(
        _target,
        1,
        {
            sf = self._sf,
            rect = SDL.CreateRect(0, 0, self._sf.w, self._sf.h)
        }
    )
    return true
end

SDL图像.渲染开始 = SDL图像.渲染清除
function SDL图像:渲染结束()
    table.remove(_target, 1)
end

--PremultiplyAlpha

return SDL图像
