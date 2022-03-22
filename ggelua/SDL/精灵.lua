-- @Author: GGELUA
-- @Date:   2021-09-17 08:26:43
-- @Last Modified by    : GGELUA
-- @Last Modified time  : 2022-03-22 21:57:23

local SDL = require('SDL')
SDL.IMG_Init()

local SDL精灵 = class 'SDL精灵'

local function _载入纹理(rd, p)
    if not rd or p == 0 or not p then
        return
    end
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    if type(p) == 'string' then --文件路径
        return assert(rd:LoadTexture(p), SDL.GetError())
    elseif ggetype(p) == 'SDL纹理' then
        return p:取对象()
    elseif ggetype(p) == 'SDL图像' and p:取对象() then
        return assert(rd:CreateTextureFromSurface(p:取对象()), SDL.GetError())
    elseif ggetype(p) == 'SDL_Texture' then
        return p
    elseif ggetype(p) == 'SDL_Surface' then
        return assert(rd:CreateTextureFromSurface(p), SDL.GetError())
    end
end

function SDL精灵:SDL精灵(p, x, y, w, h)
    self._win = SDL._win --默认窗口
    self._dr = SDL.CreateRect(x, y, w, h)
    --self._f,self._deg = 0,0 --翻转,旋转
    self._x = 0
    self._y = 0
    self.宽度 = 0
    self.高度 = 0
    self._tex = p and _载入纹理(self._win:取渲染器(), p)

    if self._tex then
        self._win._texs[self] = self._tex --FIXME　重复
        if w then
            self:置区域(x, y, w, h)
        else
            local _, _, w, h = self._tex:QueryTexture()
            self.宽度 = w
            self.高度 = h
            self._dr:SetRectWH(w, h)
        end
    elseif x and y and w and h then
        self:置区域(x, y, w, h)
        self.宽度 = w
        self.高度 = h
    end
end

function SDL精灵:复制()
    local r = SDL精灵()
    r._win = self._win
    r._tex = self._tex
    for k, v in pairs(self) do
        if type(v) == 'number' then
            r[k] = v
        end
    end
    r._dr:SetRectWH(self._dr:GetRectWH())
    if self._sr then
    --tab切换
    end
    return r
end

function SDL精灵:置坐标(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if x and y then
        if self._hx then --中心
            x, y = x - self._hx, y - self._hy
        end
        self._x, self._y = x, y
        self._dr:SetRectXY(x, y)
    end
end

function SDL精灵:显示(x, y)
    self:置坐标(x, y)

    local tex = self._tex
    local win = self._win
    if tex then
        tex:SetTextureColorMod(self._r, self._g, self._b) --纹理重复引用，必须实时修改
        tex:SetTextureAlphaMod(self._a)
        tex:SetTextureBlendMode(self._blend)
        tex:SetTextureScaleMode(self._scale)
        
        if self._f or self._deg then --src,dst,旋转，翻转，翻转中心
            win:显示纹理(tex, self._sr, self._dr, self._deg, self._f, self._ax, self._ay)
            if self._hl then --高亮
                tex:SetTextureBlendMode(SDL.BLENDMODE_ADD)
                tex:SetTextureColorMod(200, 200, 200, 128)
                win:显示纹理(tex, self._sr, self._dr, self._deg, self._f, self._ax, self._ay)
            end
        else
            win:显示纹理(tex, self._sr, self._dr)
            if self._hl then
                tex:SetTextureBlendMode(SDL.BLENDMODE_ADD)
                tex:SetTextureColorMod(200, 200, 200, 128)
                win:显示纹理(tex, self._sr, self._dr)
            end
        end
    else
        win:置颜色(self._r, self._g, self._b, self._a)
        win:画矩形(self._dr, true) --实心
    end
    return self
end

function SDL精灵:显示中心()
    if self._hx then
        local win = self._win
        win:置颜色(255, 255, 0, 255)
        local x, y = self._x, self._y
        win:画点(x - 1, y - 1)
        win:画点(x, y - 1)
        win:画点(x + 1, y - 1)
        win:画点(x, y)
    end
    return self
end

function SDL精灵:置纹理(tex)
    if ggetype(tex) == 'SDL_Texture' then
        self._tex = tex
    elseif ggetype(tex) == 'SDL纹理' then
        self._tex = tex:取对象()
    end
    if self._tex then
        local _, _, w, h = self._tex:QueryTexture()
        self.宽度, self.高度 = w, h
        self._dr:SetRectWH(w, h)
    end
    return self
end

function SDL精灵:取纹理()
    return self._tex
end
--@param SDL_ScaleMode
function SDL精灵:置过滤(v)
    self._scale = v
    -- if self._tex then
    --     self._tex:SetTextureScaleMode(v)
    -- end
    return self
end

function SDL精灵:取过滤()
    return self._scale
    -- if self._tex then
    --     return self._tex:GetTextureScaleMode()
    -- end
end

function SDL精灵:置区域(x, y, w, h)
    if x and y and w and h then
        x = math.floor(x)
        y = math.floor(y)
        w = math.floor(w)
        h = math.floor(h)
        self.区域宽度, self.区域高度 = w, h
        self._dr:SetRectWH(w, h)
        self._sr = SDL.CreateRect(x, y, w, h)
    else
        self.区域宽度, self.区域高度 = nil, nil
        self._dr:SetRectWH(self.宽度, self.高度)
        self._sr = nil
    end
    return self
end

function SDL精灵:置缩放(x, y)
    y = math.floor(self.高度 * (y or x))
    x = math.floor(self.宽度 * x)
    self._dr:SetRectWH(x, y)
    return self
end

function SDL精灵:置左右翻转(v)
    local flip = self._f or 0
    self._f = v and (flip | 1) or (flip & ~1)
    if self._f == 0 then
        self._f = nil
    end
    return self
end

function SDL精灵:置上下翻转(v)
    local flip = self._f or 0
    self._f = v and (flip | 2) or (flip & ~2)
    if self._f == 0 then
        self._f = nil
    end
    return self
end
--@param 360度
--@param 中心x
--@param 中心y
function SDL精灵:置旋转(v, x, y)
    self._deg = v
    self._ax = x or self._hx
    self._ay = y or self._hy
    return self
end

function SDL精灵:置透明(a, x, y)
    if self._tex then
        if a > 255 then
            a = 255
        elseif a < 0 then
            a = 0
        end
        --self._tex:SetTextureBlendMode(SDL.BLENDMODE_BLEND)
        --self._tex:SetTextureAlphaMod(math.floor(a))
        self:置混合(SDL.BLENDMODE_BLEND)
        self._a = math.floor(a)
    else
        self._a = math.floor(a)
    end
    return self
end

function SDL精灵:取透明(x, y)
    if self._tex then
        if x and y then
            return self._tex:GetTextureAlpha(x - self._x, y - self._y)
        end
        return self._a or 0 --self._tex:GetTextureAlphaMod()
    end
    return self._a or 0
end

function SDL精灵:置颜色(r, g, b, a)
    self._r = r or 255
    self._g = g or 255
    self._b = b or 255
    self._a = a or 255
    if self._tex then
        --self._tex:SetTextureColorMod(r,g,b)
        if a then
            self:置透明(a)
        end
    end
    return self
end

function SDL精灵:取颜色()
    -- if self._tex then
    --     local r,g,b = self._tex:SetTextureColorMod()
    --     return r,g,b,self._tex:GetTextureAlphaMod()
    -- end
    return self._r, self._g, self._b, self._a
end

function SDL精灵:置混合(v) --ComposeCustomBlendMode
    self._blend = v
    if self._tex then
        return self._tex:SetTextureBlendMode(v)
    end
end

function SDL精灵:取混合()
    -- if self._tex then
    --     return self._tex:GetTextureBlendMode()
    -- end
    return self._blend
end

function SDL精灵:置中心(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if x and y then
        self._hx, self._hy = math.floor(x), math.floor(y)
    end
    return self
end

function SDL精灵:取中心()
    return self._hx, self._hy
end

function SDL精灵:加中心(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if self._hx then
        x = math.floor(x)
        y = math.floor(y)
        self._hx = self._hx + x
        self._hy = self._hy + y
    end
    return self
end

function SDL精灵:减中心(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if self._hx then
        x = math.floor(x)
        y = math.floor(y)
        self._hx = x - self._hx
        self._hy = x - self._hy
    end
    return self
end

function SDL精灵:中心减(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if self._hx then
        x = math.floor(x)
        y = math.floor(y)
        self._hx = self._hx - x
        self._hy = self._hy - y
    end
    return self
end

function SDL精灵:取坐标()
    return self._x, self._y
end

function SDL精灵:取宽高()
    return self.宽度, self.高度
end

function SDL精灵:取矩形()
    if not self._rect then
        self._rect = require('SDL.矩形')(self._dr):置颜色(255, 0, 0)
    end
    return self._rect
end

function SDL精灵:检查点(x, y)
    -- if not y and ggetype(x) == 'GGE坐标' then
    --     x,y = x:unpack()
    -- end
    local _x, _y = self._x, self._y
    local _w, _h = self.宽度, self.高度
    return (x >= _x) and (x < _x + _w) and (y >= _y) and (y < _y + _h)
end

function SDL精灵:取像素(x, y)
    -- if not y and ggetype(x) == 'GGE坐标' then
    --     x,y = x:unpack()
    -- end
    if self._tex and x and y then
        return self._tex:GetTexturePixel(x - self._x, y - self._y) --argb
    end
    return 0, 0, 0, 0
end

function SDL精灵:检查透明(x, y)
    -- if not y and ggetype(x) == 'GGE坐标' then
    --     x,y = x:unpack()
    -- end
    if self._tex and x and y then
        return self._tex:GetTextureAlpha(x - self._x, y - self._y) > 0
    end
    return false
end

function SDL精灵:置高亮(r, g, b, a)
    self._hl = r
    return self
end

function SDL精灵:取高亮()
    return self._hl
end

return SDL精灵
