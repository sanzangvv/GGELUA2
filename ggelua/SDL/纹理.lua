-- @Author: baidwwy
-- @Date:   2021-08-18 13:24:54
-- @Last Modified by: baidwwy
-- @Last Modified time: 2022-01-05 05:01:19

local _ENV = require('SDL')
IMG_Init()

local SDL纹理 = class 'SDL纹理'

local function _载入纹理(rd, a, b, c, d, e)
    if not rd then
        return
    end
    local tp = ggetype(a)

    if tp == 'number' and type(b) == 'number' then --默认 SDL_TEXTUREACCESS_TARGET, SDL_PIXELFORMAT_ARGB8888
        return assert(rd:CreateTexture(a, b, c, d), SDL.GetError()) --宽度,高度,SDL_TEXTUREACCESS_?,SDL_PIXELFORMAT_?
    elseif tp == 'string' then --默认 SDL_TEXTUREACCESS_STATIC
        return assert(rd:LoadTexture(a, b), SDL.GetError()) --FILE, SDL_TEXTUREACCESS_?
    elseif tp == 'SDL_Texture' then
        return a
    elseif tp == 'SDL_Surface' then
        return assert(rd:CreateTextureFromSurface(a, b), SDL.GetError())
    elseif tp == 'SDL图像' and a:取对象() then
        return assert(rd:CreateTextureFromSurface(a:取对象(), b), SDL.GetError())
    elseif tp == 'SDL读写' and a:取对象() then
        return assert(rd:LoadTexture_RW(a:取对象(), b), SDL.GetError())
    elseif tp == 'SDL_RWops' then
        return assert(rd:LoadTexture_RW(a, b), SDL.GetError())
    elseif a ~= nil then
        error('未知模式')
    end
end

function SDL纹理:SDL纹理(...)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win = SDL._win --默认窗口
    self._tex = _载入纹理(self._win:取渲染器(), ...)

    if ggetype(self._tex) == 'SDL_Texture' then
        self._win._texs[self] = self._tex
        self._format, self._access, self.宽度, self.高度 = self._tex:QueryTexture()
        if self._access == SDL.TEXTUREACCESS_TARGET then
            self._tex:SetTextureBlendMode(SDL.BLENDMODE_BLEND)
        end
    end
end

-- function SDL纹理:更新(pixels,pitch)
--     self._tex:UpdateTexture(nil,pixels,pitch)
--     --self._tex:UpdateYUVTexture()
-- end

function SDL纹理:取对象()
    return self._tex
end

function SDL纹理:取模式()
    return self._access
end

function SDL纹理:复制()
end

function SDL纹理:锁定(x, y, w, h)
    if self._tex then
        if self._access ~= SDL.TEXTUREACCESS_STREAMING then
            error('"无法锁定"')
        end
        local rect
        if x and y and w and h then
            rect = CreateRect(x, y, w, h)
        end
        return self._tex:LockTexture(rect)
    end
end

function SDL纹理:解锁()
    if self._tex then
        self._tex:UnlockTexture()
    end
    return self
end

function SDL纹理:到灰度()
    return self
end

function SDL纹理:到精灵()
    return require('SDL.精灵')(self)
end

function SDL纹理:取像素(x, y)
end

function SDL纹理:置像素(x, y, r, g, b, a)
    return self
end

function SDL纹理:保存文件(file, tp, quality)
end

function SDL纹理:置过滤(v)
    if self._tex then
        self._tex:SetTextureScaleMode(v)
    end
    return self
end

function SDL纹理:渲染清除(r, g, b, a)
    if self._access == SDL.TEXTUREACCESS_TARGET then
        return self._win:置渲染区(self._tex) and self._win:渲染清除(r, g, b, a)
    end
end

SDL纹理.渲染开始 = SDL纹理.渲染清除
function SDL纹理:渲染结束()
    self._win:置渲染区()
end
return SDL纹理
