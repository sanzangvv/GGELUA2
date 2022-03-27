-- @Author              : GGELUA
-- @Date                : 2022-03-07 18:52:00
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-28 02:12:44

local gge = require('ggelua')
local SDL = require('SDL')
local ggetype = ggetype
local TTF = SDL.TTF_Init()

local SDL文字 = class('SDL文字')

function SDL文字:SDL文字(file, size, aliasing, w)
    self._win = SDL._win --默认窗口
    self._anti = aliasing ~= false --抗锯齿
    self._rnw = w --折行宽度
    self._size = tonumber(size) or 14

    local tp = ggetype(file)
    if tp == 'string' then
        if gge.platform == 'Android' or gge.platform == 'iOS' then --读到内存
            local data = SDL.LoadFile(file)
            self._rw = require('SDL.读写')(data, #data)
            self._font = TTF.OpenFontRW(self._rw:取对象(), self._size)
        else
            self._file = file
            self._font = TTF.OpenFont(file, self._size)
        end
    elseif tp == 'SDL读写' then
        self._rw = file
        self._font = TTF.OpenFontRW(file:取对象(), self._size)
    elseif tp == 'SDL_RWops' then
        self._rw = file
        self._font = TTF.OpenFontRW(file, self._size)
    end

    if self._font then
        SDL._ttfs[self] = self._font
        self:置颜色(255, 255, 255)
    else
        error(SDL.GetError())
    end
end

function SDL文字:置窗口(v)
    self._win = v
end

function SDL文字:复制()
    if self._file then
        return SDL文字(self._file, self._size, self._anti, self._rnw):置颜色(self._r, self._g, self._b, self._a)
    end
    self._rw:置位置(0)
    return SDL文字(self._rw, self._size, self._anti, self._rnw):置颜色(self._r, self._g, self._b, self._a)
end

function SDL文字:显示(x, y, t)
    if not t and ggetype(x) == 'GGE坐标' then
        t = y
        x, y = x:unpack()
    end
    if not self._cache then
        self._cache = self._font:CreateFontCache(self._win:取渲染器())
    end
    self._cache:Draw(x, y, t)
end

function SDL文字:取纹理(t, ...)
    if t and t ~= '' then
        local sf = self:取图像(t, ...)
        return self._win:创建纹理(sf)
    end
end

function SDL文字:取精灵(t, ...)
    if t and t ~= '' then
        local sf = self:取图像(t, ...)
        return self._win:创建精灵(sf)
    end
    return self._win:创建精灵()
end

function SDL文字:取图像(t, ...)
    if t and t ~= '' then
        if select('#', ...) > 0 then
            t = tostring(t):format(...)
        end
        if self._rnw then --折行
            if self._ba or self._br or self._bg or self._bb then --有背景
                return self._win:创建图像(self._font:RenderUTF8_Shaded_Wrapped(t, self._r, self._g, self._b, self._a, self._br, self._bg, self._bb, self._ba, self._rnw))
            elseif self._anti then --抗锯齿
                return self._win:创建图像(self._font:RenderUTF8_Blended_Wrapped(t, self._r, self._g, self._b, self._a, self._rnw))
            else
                return self._win:创建图像(self._font:RenderUTF8_Solid_Wrapped(t, self._r, self._g, self._b, self._a, self._rnw))
            end
        end
        if self._ba or self._br or self._bg or self._bb then --有背景
            return self._win:创建图像(self._font:RenderUTF8_Shaded(t, self._r, self._g, self._b, self._a, self._br, self._bg, self._bb, self._ba))
        elseif self._anti then --抗锯齿
            return self._win:创建图像(self._font:RenderUTF8_Blended(t, self._r, self._g, self._b, self._a))
        else
            return self._win:创建图像(self._font:RenderUTF8_Solid(t, self._r, self._g, self._b, self._a))
        end
    end
end

function SDL文字:取描边图像(t, r, g, b, a)
    if t and t ~= '' then
        local sfa = self._font:RenderUTF8_Solid(t, self._r, self._g, self._b, self._a)
        local sfb = self._font:RenderUTF8_Solid(t, r or 0, g or 0, b or 0, a)
        local sf = SDL.CreateRGBSurfaceWithFormat(sfa.w + 2, sfa.h + 2)
        local r = SDL.CreateRect(1, 0, 0, 0)
        sfb:BlitSurface(nil, sf, r)
        r:SetRectXY(0, 1)
        sfb:BlitSurface(nil, sf, r)
        r:SetRectXY(2, 1)
        sfb:BlitSurface(nil, sf, r)
        r:SetRectXY(1, 2)
        sfb:BlitSurface(nil, sf, r)
        r:SetRectXY(1, 1)
        sfa:BlitSurface(nil, sf, r)
        return require('SDL.图像')(sf)
    end
end
--轮廓对宋体无效
function SDL文字:取描边精灵(t, r, g, b, a)
    if t and t ~= '' then
        return self._win:创建精灵(self:取描边图像(t, r, g, b, a))
    end
    return self._win:创建精灵()
end

function SDL文字:取投影图像(t, r, g, b, a)
    if t and t ~= '' then
        local sfa = self._font:RenderUTF8_Solid(t, self._r, self._g, self._b, self._a)
        local sfb = self._font:RenderUTF8_Solid(t, r or 0, g or 0, b or 0, a)
        local sf = SDL.CreateRGBSurfaceWithFormat(sfa.w + 1, sfa.h + 1)
        local r = SDL.CreateRect(1, 0, 0, 0)
        sfb:BlitSurface(nil, sf, r)
        r:SetRectXY(0, 1)
        sfb:BlitSurface(nil, sf, r)
        r:SetRectXY(1, 1)
        sfb:BlitSurface(nil, sf, r)
        r:SetRectXY(0, 0)
        sfa:BlitSurface(nil, sf, r)
        return require('SDL.图像')(sf)
    end
end

function SDL文字:取投影精灵(t, r, g, b, a)
    if t and t ~= '' then
        return self._win:创建精灵(self:取投影图像(t, r, g, b, a))
    end
    return self._win:创建精灵()
end

SDL.TTF_STYLE_NORMAL = 0x00 --正常
SDL.TTF_STYLE_BOLD = 0x01 --粗体
SDL.TTF_STYLE_ITALIC = 0x02 --斜体
SDL.TTF_STYLE_UNDERLINE = 0x04 --下划线
SDL.TTF_STYLE_STRIKETHROUGH = 0x08 --删除线
function SDL文字:取样式()
    return self._font:GetFontStyle()
end

function SDL文字:置样式(v)
    self._font:SetFontStyle(v)
    return self
end

function SDL文字:取轮廓()
    return self._font:GetFontOutline()
end

function SDL文字:置轮廓(v)
    self._font:SetFontOutline(v)
    return self
end
SDL.TTF_HINTING_NORMAL = 0
SDL.TTF_HINTING_LIGHT = 1
SDL.TTF_HINTING_MONO = 2
SDL.TTF_HINTING_NONE = 3
SDL.TTF_HINTING_LIGHT_SUBPIXEL = 4
function SDL文字:置标志(v)
    self._font:SetFontHinting(v)
    return self
end

function SDL文字:取标志()
    return self._font:GetFontHinting()
end

function SDL文字:置颜色(r, g, b, a)
    if self._r ~= r or self._g ~= g or self._b ~= b or self._a ~= a then
        self._t = nil
        self._a = a
        self._r = r
        self._g = g
        self._b = b
    end

    return self
end

function SDL文字:取颜色()
    return self._r, self._g, self._b, self._a
end

function SDL文字:置背景颜色(r, g, b, a)
    self._t = nil
    self._ba = a
    self._br = r
    self._bg = g
    self._bb = b
    return self
end

function SDL文字:取背景颜色()
    return self._br, self._bg, self._bb, self._ba
end
--自动折行
function SDL文字:置宽度(w)
    self._t = nil
    self._rnw = w
    return self
end
--动态修改文字大小
function SDL文字:置大小(v)
    if v ~= self._size then
        self._size = v
        self._t = nil
        self._font:SetFontSize(v)
    end
    return self
end

function SDL文字:置抗锯齿(v)
    self._t = nil
    self._anti = v
    return self
end

function SDL文字:取宽度(t)
    return (self._font:SizeUTF8(t))
end

function SDL文字:取高度(t)
    return self._font:FontHeight()
end

function SDL文字:取宽高(t)
    return self._font:SizeUTF8(t)
end

-- function SDL文字:Ascent()
--     return self._font:FontAscent()
-- end

-- function SDL文字:Descent()
--     return self._font:FontDescent()
-- end

-- function SDL文字:LineSkip()
--     return self._font:FontLineSkip()
-- end

-- function SDL文字:GetFontKerning()
--     return self._font:GetFontKerning()
-- end

-- function SDL文字:SetFontKerning(v)
--     return self._font:SetFontKerning(v)
-- end

-- function SDL文字:Faces()
--     return self._font:FontFaces()
-- end

-- function SDL文字:FaceIsFixedWidth()
--     return self._font:FontFaceIsFixedWidth()
-- end

-- function SDL文字:取字体名称()
--     return self._font:FontFaceFamilyName()
-- end

-- function SDL文字:取类型名称()
--     return self._font:FontFaceStyleName()
-- end

return SDL文字
