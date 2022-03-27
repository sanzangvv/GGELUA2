-- @Author              : GGELUA
-- @Date                : 2022-03-07 18:52:00
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-28 02:33:33

local gge = require('ggelua')
local SDL = require('SDL')

local SDL渲染 = class('SDL渲染')

function SDL渲染:SDL渲染(t)
    if type(t) == 'string' and t:sub(4) == 'sdl.' then
        print(t:match('sdl%.(%a+)'))
    elseif t == 'bgfx' then
    else
        self._rd = assert(self._win:CreateRenderer(-1, 10), SDL.GetError()) --10=SDL_RENDERER_ACCELERATED|SDL_RENDERER_TARGETTEXTURE
        self._rd:SetRenderDrawBlendMode(SDL.BLENDMODE_BLEND)
    end
    assert(self._rd:RenderTargetSupported(), '不支持')
    self._texs = setmetatable({}, {__mode = 'kv'}) --纹理列表
    local name = self._rd:GetRendererInfo().name
    if name == 'direct3d11' then
        self._rt = self._rd:CreateTexture(self.宽度, self.高度, SDL.TEXTUREACCESS_TARGET)
    end
    SDL.Log('渲染器 %s %d %d', name, self.宽度, self.高度)

    self._cr = {} --clip
    self._vr = SDL.CreateRect() --view
    -- for i=0,SDL.GetNumRenderDrivers()-1 do--CreateRenderer第1参数来启用相应的渲染器，(-1)第1个
    --     SDL.Log("渲染器 %d %s",i,SDL.GetRenderDriverInfo(i).name)
    -- end

    -- for k,v in pairs(self._rd:GetRendererInfo()) do
    --     print(k,v)
    -- end

    -- for i,v in ipairs(self._rd:GetRendererInfo().texture_formats) do--支持格式
    --     print(i,v,SDL.GetPixelFormatName(v))
    -- end

    -- for k,v in pairs(self._win:GetWindowDisplayMode()) do
    --     if k == 'format' then
    --         print(SDL.GetPixelFormatName(v))
    --     end
    --     print(string.format( "%s,%s",k,v ))
    -- end

    -- SDL.Log("OutputSize %d,%d",self._rd:GetRendererOutputSize())
    -- SDL.Log("LogicalSize %d,%d",self._rd:RenderGetLogicalSize())
    --print(self._rd:RenderGetIntegerScale())

    --print(SDL.GetPixelFormatName(self._win:GetWindowPixelFormat()))
end

function SDL渲染:__gc()
    if self._rd then
        print('DestroyTexture')
        for k, v in pairs(self._texs) do
            v:__gc()
        end
        self._texs = {} --纹理
        print('DestroyRenderer')
        self._rd:DestroyRenderer()
        self._rd = nil
        collectgarbage()
    end
end

function SDL渲染:显示纹理(tex, srcrect, dstrect, angle, flip, centerx, centery)
    if self._rd then
        if angle or flip then
            return self._rd:RenderCopyEx(tex, srcrect, dstrect, angle, flip, centerx, centery)
        end
        return self._rd:RenderCopy(tex, srcrect, dstrect)
    end
end

function SDL渲染:取渲染器()
    return self._rd
end

-- function SDL渲染:是否支持渲染区()
--     return self._rd and self._rd:RenderTargetSupported()
-- end

function SDL渲染:创建渲染区(w, h)
    if self._rd then
        return self._rd:CreateTexture(w, h) --SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_TARGET
    end
end

function SDL渲染:置渲染区(tex)
    if self._rd and tex then
        if self._tg then
            return false
        else
            self._tg = tex
            if ggetype(tex) == 'SDL纹理' then
                self._rd:SetRenderTarget(tex:取对象())
            else
                self._rd:SetRenderTarget(tex)
            end
            return true
        end
    end
    self._tg = nil
    self._rd:SetRenderTarget()
end

function SDL渲染:取渲染区(tex)
    return self._tg
end

function SDL渲染:渲染清除(r, g, b, a)
    if self._rd then
        if self._rt then
            self:置渲染区(self._rt)
        end
        self._rd:SetRenderDrawColor(r, g, b, a)
        return self._rd:RenderClear()
    elseif self._sf then
        self._sf:FillRect(r, g, b)
    end
    return true
end

SDL渲染.渲染开始 = SDL渲染.渲染清除
function SDL渲染:渲染结束()
    if self._rd then
        if self._rt then
            self:置渲染区()
            self._rd:RenderCopy(self._rt)
        end
        self._rd:RenderPresent()
    else
        self._win:UpdateWindowSurface()
    end
end

function SDL渲染:置颜色(r, g, b, a)
    if self._rd then
        self._rd:SetRenderDrawColor(r, g, b, a)
    else
        self._sf:SetSurfaceColorMod(r, g, b, a)
    end
    return self
end

function SDL渲染:画点(x, y)
    if self._rd then
        self._rd:RenderDrawPoint(x, y)
    end
    return self
end

function SDL渲染:画线(x, y, x1, y1)
    if self._rd then
        self._rd:RenderDrawLine(x, y, x1, y1)
    end
    return self
end

function SDL渲染:画矩形(a, ...)
    if self._rd then
        local tp = ggetype(a)
        local rect, fill
        if tp == 'SDL矩形' then
            rect = a:取对象()
            fill = ...
        elseif tp == 'SDL_Rect' then
            rect = a
            fill = ...
        elseif tp == 'number' then
            local x, y, w, h
            x, y, w, h, fill = a, ...
            rect = SDL.CreateRect(x, y, w, h)
        end

        if rect then
            if fill then
                return self._rd:RenderFillRect(rect)
            end
            return self._rd:RenderDrawRect(rect)
        end
    else
        --self._sf:FillRect(r, g, b, rect)
    end
    return self
end

function SDL渲染:置逻辑宽高(w, h)
    if self._rd:RenderSetLogicalSize(w, h) then
        if w == 0 or h == 0 then
            self.宽度, self.高度 = self._rd:GetRendererOutputSize()
        else
            self.宽度, self.高度 = w, h
        end

        self.宽度2 = self.宽度 // 2
        self.高度2 = self.高度 // 2
        if w == 0 or h == 0 then
            self._rt = nil
        else
            self._rt = self._rd:CreateTexture(self.宽度, self.高度, SDL.TEXTUREACCESS_TARGET)
            self._rt:SetTextureScaleMode(1) --SDL_ScaleModeLinear
        end
        return true
    else
        SDL.Log(SDL.GetError())
    end
end

function SDL渲染:取逻辑宽高()
    return self._rd:RenderGetLogicalSize()
end

function SDL渲染:置区域(x, y, w, h)
    if x then
        local rect = SDL.CreateRect(x, y, w, h)
        if self._cr[1] then
            rect = self._cr[1]:IntersectRect(rect)
        end
        table.insert(self._cr, 1, rect)
    else
        table.remove(self._cr, 1)
    end
    if self._rd then
        self._rd:RenderSetClipRect(self._cr[1])
    else
        self._sf:SetClipRect(self._cr[1])
    end
    return self._cr[1]
end

function SDL渲染:取区域()
    if self._cr[1] then
        return self._cr[1]:GetRect()
    end
    return 0, 0, 引擎.宽度, 引擎.高度
end

function SDL渲染:置视图(x, y, w, h)
    if self._rd then
        if x then
            self._vr:SetRect(x, y, w, h)
            self._rd:RenderSetViewport(self._vr)
        else
            self._rd:RenderSetViewport()
        end
    end
    return self
end

function SDL渲染:取视图()
    return self._vr:GetRect()
end

function SDL渲染:置缩放(x, y)
    if self._rd then
        self._rd:RenderSetScale(x, y)
    end
    return self
end

function SDL渲染:取缩放()
    return self._rd and self._rd:RenderGetScale()
end

function SDL渲染:取实际坐标(x, y)
    if self._rd then
        return self._rd:RenderLogicalToWindow(x, y)
    end
end

function SDL渲染:取逻辑坐标(x, y)
    if self._rd then
        return self._rd:RenderWindowToLogical(x, y)
    end
end
--如果是渲染区，则需要在渲染结束前调用
function SDL渲染:截图到图像(dst, x, y, w, h)
    if self._rd then
        if not dst then
            dst = self:创建图像(w or self.宽度, h or self.高度) --372645892=SDL_PIXELFORMAT_ARGB8888
        end
        local pixels, pitch = dst:锁定()
        local rect
        if x and y and w and h then
            rect = SDL.CreateRect(x, y, w, h)
        end
        local r = self._rd:RenderReadPixels(rect, 372645892, pixels, pitch)
        dst:解锁()
        return r and dst
    end
end

function SDL渲染:截图到文件(...)
    self:截图到图像():保存文件(...)
    return self
end
--dx11需要渲染区
function SDL渲染:截图到纹理(dst, x, y, w, h)
    if self._rd then
        if not dst then
            dst = self:创建纹理(w or self.宽度, h or self.高度, SDL.TEXTUREACCESS_STREAMING) --372645892=SDL_PIXELFORMAT_ARGB8888
        end
        local pixels, pitch = dst:锁定()
        local rect
        if x and y and w and h then
            rect = SDL.CreateRect(x, y, w, h)
        end
        local r = self._rd:RenderReadPixels(rect, 372645892, pixels, pitch)
        dst:解锁()
        return r and dst
    end
end

function SDL渲染:创建精灵(...)
    if self._rd then
        local owin = SDL._win
        SDL._win = self
        local r = require('SDL.精灵')(...)
        SDL._win = owin
        return r
    end
end

function SDL渲染:创建纹理(...)
    if self._rd then
        local owin = SDL._win
        SDL._win = self
        local r = require('SDL.纹理')(...)
        SDL._win = owin
        return r
    end
end

function SDL渲染:创建文字(...)
    if self._rd then
        local owin = SDL._win
        SDL._win = self
        local r = require('SDL.文字')(self, ...)
        SDL._win = owin
        return r
    end
end

return SDL渲染
