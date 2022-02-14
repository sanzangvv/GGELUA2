-- @Author: GGELUA
-- @Date:   2021-09-19 06:42:20
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-11 12:55:43

local SDL = require('SDL')
local gge = require('ggelua')
local type = type
local pairs = pairs
local ipairs = ipairs
local ggexpcall = ggexpcall
local next = next

local ggeinit = SDL.RegisterEvents()

local rd = require('SDL.渲染')

local SDL窗口 = class('SDL窗口', 'SDL渲染')

function SDL窗口:SDL窗口(t)
    for k, v in pairs(t) do
        if self[k] then
            error('名称冲突:' .. k)
        else
            self[k] = v
        end
    end
    self.标题 = t.标题 or 'GGELUA Game Engine'
    self.原始标题 = self.标题
    self.宽度 = t.宽度 or 800
    self.高度 = t.高度 or 600
    self.帧率 = t.帧率 or 60
    self.是否全屏 = t.全屏
    self.宽度2 = self.宽度 // 2
    self.高度2 = self.高度 // 2
    self.x = 0
    self.y = 0

    local flags = 0x00000004 --SDL_WINDOW_SHOWN
    SDL.SetHint('SDL_RENDER_BATCHING', '1')
    if gge.platform == 'Android' or gge.platform == 'iOS' then
        self.是否全屏 = t.全屏 ~= false
        t.渲染器 = 'opengles2'

        if self.宽度 > self.高度 then --横向
            SDL.SetHint('SDL_IOS_ORIENTATIONS', 'LandscapeLeft LandscapeRight')
        else
            SDL.SetHint('SDL_IOS_ORIENTATIONS', 'Portrait')
        end

        --SDL.SetHint('SDL_RENDER_SCALE_QUALITY', 'linear')
        if self.是否全屏 then
            flags = flags | 0x00001000 --SDL_WINDOW_FULLSCREEN_DESKTOP
        end
        if SDL._win then
            return
        end
    else
        SDL.SetHint('SDL_IME_SHOW_UI', '1')
    end

    if type(t.渲染器) == 'string' then
        SDL.SetHint('SDL_RENDER_DRIVER', t.渲染器)
        if t.渲染器 == 'opengl' then
            flags = flags | 0x00000002 --SDL_WINDOW_OPENGL
        end
    end

    if self.是否全屏 then
        flags = flags | 0x00000001 --SDL_WINDOW_FULLSCREEN
    end
    if t.无边框 then --隐藏边框
        flags = flags | 0x00000010 --SDL_WINDOW_BORDERLESS
    end
    if t.隐藏 then --隐藏窗口
        flags = flags | 0x00000008 --SDL_WINDOW_HIDDEN
    end
    if t.可调整 then --可调整
        flags = flags | 0x00000020 --SDL_WINDOW_RESIZABLE
    end
    if t.任务栏 == false then --隐藏任务栏
        flags = flags | 0x00010000 --SDL_WINDOW_SKIP_TASKBAR
    end

    self._win = assert(SDL.CreateWindow(self.标题, t.x, t.y, self.宽度, self.高度, flags), SDL.GetError())
    local id = self._win:GetWindowID()
    SDL._wins[id] = self

    if gge.platform == 'Windows' and ggetype(t.父窗口) == 'SDL窗口' then
        self._win:SetParent(t.父窗口._win)
    end

    SDL.ShowCursor(t.鼠标 ~= false)
    if not SDL._win then --主窗口
        SDL._mth = SDL.ThreadID()
        SDL._win = self
        SDL.FPS = self.帧率
        if SDL.FPS > 0 then
            SDL._ft = 1 / SDL.FPS
        end
    end

    if t.渲染器 == false then
        self._winsf = self._win:GetWindowSurface()
        self._sfrect = SDL.CreateRect(0, 0, self.宽度, self.高度)
    else
        self:SDL渲染() --创建渲染器
    end
    SDL.CreateEvent(ggeinit, id):PushEvent()

    --设置黑色
    self:渲染清除(0, 0, 0)
    self:渲染结束()

    self._reg = setmetatable({}, {__mode = 'v'}) --注册消息
    self._tick = {}
    self._timer = {} --定时器
end

local function _Sendreg(self, k, ...)
    for _, v in pairs(self._reg) do
        if type(v[k]) == 'function' then
            ggexpcall(v[k], v, ...)
        end
    end
end

local function _Sendmsg(self, k, ...)
    if type(self[k]) == 'function' then
        return ggexpcall(self[k], self, ...)
    end
end

local function _Destroy(self)
    _Sendmsg(self, '销毁事件')
    _Sendreg(self, '销毁事件')
    if self._winsf then
        self._winsf:__gc()
    end
    if SDL._win == self then
        for _, v in pairs(SDL._sfs) do
            v:__gc()
        end
        SDL._sfs = {} --图像
        for _, v in pairs(SDL._mixs) do
            v:__gc()
        end
        SDL._mixs = {} --音效
        for _, v in pairs(SDL._ttfs) do
            v:__gc()
        end
        SDL._ttfs = {} --文字
        for _, v in pairs(SDL._wins) do
            if v ~= self then
                _Destroy(v)
            end
        end
        collectgarbage()
    end

    self[rd]:__gc() --纹理

    if self._win then
        print('DestroyWindow', self.标题)
        SDL._wins[self._win:GetWindowID()] = nil
        self._win:DestroyWindow()
        collectgarbage()
    end
    if SDL._win == self then
        print('QuitAll')
        if SDL.IMG then
            SDL.IMG.Quit()
        end
        if SDL.MIX then
            SDL.MIX.Quit()
        end
        if SDL.TTF then
            SDL.TTF.Quit()
        end
        gge.exit()
        SDL.Quit()
    end
    self._win = nil
end

function SDL窗口:_Event(t, ...)
    if t == nil then
        if next(self._tick) then --协程定时
            local oc = SDL.GetTicks()
            for co, t in pairs(self._tick) do
                if oc >= t then
                    coroutine.xpcall(co)
                end
            end
        end
        if next(self._timer) then --函数定时
            local oc = SDL.GetTicks()
            for i, t in ipairs(self._timer) do
                if oc >= t.time then
                    t.ms = ggexpcall(t.fun, t.ms, ...)
                    if t.ms == 0 or type(t.ms) ~= 'number' then
                        table.remove(self._timer, i)
                        break
                    else
                        t.time = t.ms + oc
                    end
                end
            end
        end

        if self._quit then
            _Destroy(self)
            return SDL._win == self
        else
            self.dt = ...
            _Sendreg(self, '更新事件', ...) --注册事件
            _Sendmsg(self, '更新事件', ...)
            _Sendmsg(self, '渲染事件', ...)
        end
    elseif t == ggeinit then
        if not self._inited and self.初始化 then
            ggexpcall(self.初始化, self)
            self._inited = true
        end
    elseif t == 0x200 or t == 0x1000 then --SDL_WINDOWEVENT|SDL_DROPFILE|SDL_DROPTEXT
        if t == 0x200 then --SDL_WINDOWEVENT
            local event, t = ...
            if event == SDL.WINDOWEVENT_SIZE_CHANGED then --更改大小
                --SDL.Log('WINDOWEVENT_SIZE_CHANGED %d %d', t.data1, t.data2)

                if gge.platform == 'Android' or gge.platform == 'iOS' then
                    if self._inited then
                        return
                    end
                    local w, h, scale = t.data1, t.data2
                    if w < h then
                        w, h = h, w
                    end
                    SDL.Log('渲染宽高 %d %d %d %d', self.宽度, self.高度, w, h)
                    if self.宽度 > self.高度 then --横屏
                        scale = self.高度 / h
                    else
                        scale = self.宽度 / w
                    end
                    w, h = math.floor(w * scale), math.floor(h * scale) --刘海？
                    SDL.Log('逻辑宽高 %d %d', w, h)
                    self:置逻辑宽高(w, h)

                    return --不发出
                else
                    self.宽度, self.高度 = t.data1, t.data2
                    self.宽度2, self.高度2 = t.data1 // 2, t.data2 // 2

                    if self._winsf then --更改大小后sf会失效，只能在SDL_WINDOWEVENT_SIZE_CHANGED重新获取
                        self._winsf:__gc() --需要先把旧的删除
                        self._winsf = self._win:GetWindowSurface()
                    elseif self._rt then
                        self._rt = self._rd:CreateTexture(self.宽度, self.高度, SDL.TEXTUREACCESS_TARGET)
                    end
                end
            elseif event == SDL.WINDOWEVENT_ENTER then --鼠标进入
                SDL.ShowCursor(self.鼠标 ~= false)
            end
        end
        _Sendreg(self, '窗口事件', ...)
        _Sendmsg(self, '窗口事件', ...)
    elseif t == 0x300 or t == 0x301 then --SDL_KEYDOWN|SDL_KEYUP
        _Sendreg(self, '键盘事件', ...)
        _Sendmsg(self, '键盘事件', ...)
    elseif t == 0x302 then --SDL_TEXTEDITING
        _Sendreg(self, '输入法事件', ...)
        _Sendmsg(self, '输入法事件', ...)
    elseif t == 0x303 then --SDL_TEXTINPUT
        _Sendreg(self, '输入事件', ...)
        _Sendmsg(self, '输入事件', ...)
    elseif t == 0x400 or t == 0x401 or t == 0x402 or t == 0x403 then --SDL_MOUSEMOTION|SDL_MOUSEBUTTONDOWN|SDL_MOUSEBUTTONUP|SDL_MOUSEWHEEL
        _Sendreg(self, '鼠标事件', ...)
        _Sendmsg(self, '鼠标事件', ...)
    elseif t == 0x1100 or t == 0x1101 then --SDL_AUDIODEVICEADDED
        _Sendreg(self, '设备事件', ...)
        _Sendmsg(self, '设备事件', ...)
    elseif t == 0x2000 then --SDL_RENDER_TARGETS_RESET
        print('渲染区丢失')
        if self._rt then
        -- body
        end
    elseif t == 0x2001 then --SDL_RENDER_DEVICE_RESET
        print('设备重启')
    else
        SDL.Log('event %x', t)
    end
end

function SDL窗口:注册事件(t)
    if type(t) == 'table' then
        table.insert(self._reg, t)
        return t
    end
end
--SDL.AddTimer是线程回调
function SDL窗口:定时(ms, fun)
    if type(fun) == 'function' then
        table.insert(self._timer, {ms = ms, time = SDL.GetTicks() + ms, fun = fun})
        return
    end
    local co, main = coroutine.running()
    if not main then
        self._tick[co] = SDL.GetTicks() + ms
        coroutine.yield()
        self._tick[co] = nil
        return true
    end
end

function SDL窗口:关闭()
    self._quit = true
end

function SDL窗口:取对象()
    return self._win
end

function SDL窗口:显示图像(sf, x, y, rect)
    if self._winsf then
        self._sfrect:SetRectXY(x, y)
        return sf:BlitSurface(rect, self._winsf, self._sfrect)
    end
end

function SDL窗口:取FPS()
    return SDL.FPS
end

function SDL窗口:取ID()
    return self._win:GetWindowID()
end
SDL.MESSAGEBOX_ERROR = 0x00000010 --错误图标
SDL.MESSAGEBOX_WARNING = 0x00000020 --警告图标
SDL.MESSAGEBOX_INFORMATION = 0x00000040 --信息图标
function SDL窗口:消息框(title, message, flags)
    return self._win:ShowSimpleMessageBox(flags, tostring(title), tostring(message))
end

function SDL窗口:置隐藏(b)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    if b then
        self._win:HideWindow()
    else
        self._win:ShowWindow()
    end
end

function SDL窗口:置最前(b)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:SetWindowAlwaysOnTop(b)
end

function SDL窗口:最大化()
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:MaximizeWindow()
end

function SDL窗口:最小化()
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:MinimizeWindow()
end

function SDL窗口:置边框(b)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:SetWindowBordered(b)
end

function SDL窗口:置动态宽高(b)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:SetWindowResizable(b)
end

function SDL窗口:置最小宽高(w, h) --SDL_WINDOW_RESIZABLE
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:SetWindowMinimumSize(w, h)
end

function SDL窗口:取最小宽高() --SDL_WINDOW_RESIZABLE
    return self._win:GetWindowMinimumSize()
end

function SDL窗口:置最大宽高(w, h) --SDL_WINDOW_RESIZABLE
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:SetWindowMaximumSize(w, h)
end

function SDL窗口:取最大宽高() --SDL_WINDOW_RESIZABLE
    return self._win:GetWindowMaximumSize()
end

function SDL窗口:置标题(v, ...)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    if select('#', ...) > 0 then
        v = v:format(...)
    end
    self._win:SetWindowTitle(v)
end

function SDL窗口:取标题()
    return self._win:GetWindowTitle()
end

function SDL窗口:置图标(v)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    if ggetype(v) == 'SDL图像' then
        self._win:SetWindowIcon(v:取对象())
    end
end

function SDL窗口:置坐标(x, y)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:SetWindowPosition(x, y)
end

function SDL窗口:取坐标()
    return self._win:GetWindowPosition()
end

function SDL窗口:置宽高(w, h)
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self._win:SetWindowSize(w, h)
end

function SDL窗口:取宽高()
    return self._win:GetWindowSize()
end

function SDL窗口:置全屏(b, t) --SDL_WINDOW_FULLSCREEN_DESKTOP
    assert(SDL._mth == SDL.ThreadID(), '无法在线程中调用')
    self.是否全屏 = b
    if t then
        self._win:SetWindowDisplayMode(t)
    end
    if type(b) ~= 'number' then
        b = b and 1 or 0
    end
    return self._win:SetWindowFullscreen(b)
end

function SDL窗口:取句柄()
    return self._win:GetWindowWMInfo().info.window
end

function SDL窗口:取边框大小() --上左下右
    return self._win:GetWindowBordersSize()
end

--SetWindowGrab 锁定鼠标
--SetWindowBrightness 伽玛
--SetWindowOpacity 透明
--========================================================================================================
function SDL窗口:取屏幕键盘状态()
    if self._win then
        return self._win:IsScreenKeyboardShown()
    end
end

function SDL窗口:取键盘焦点()
    if self._win then
        return self._win:GetKeyboardFocus()
    end
end

function SDL窗口:取按键状态(key)
    if self._win then
        return self._win:GetKeyboardState(SDL.GetScancodeFromKey(key))
    end
end

function SDL窗口:取功能键状态(key)
    if self._win then
        return self._win:GetModState(key)
    end
end

function SDL窗口:取鼠标焦点()
    if self._win then
        return self._win:GetMouseFocus()
    end
end

function SDL窗口:取鼠标状态()
    if self._win then
        return SDL.GetMouseState()
    end
end

function SDL窗口:取鼠标坐标()
    if self._win then
        local _, x, y = SDL.GetMouseState()
        return x, y
    end
end

function SDL窗口:创建图像(...)
    local owin = SDL._win
    SDL._win = self
    local r = require('SDL.图像')(...)
    SDL._win = owin
    return r
end

--@param type 渲染器类型{'auto','opengl'}
function SDL窗口:创建渲染器(t)
    if self._winsf then
        self._winsf:__gc()
        self._winsf = nil
        self._sfrect = nil
    end
end

function SDL窗口:创建窗口(t)
    t.父窗口 = self
    if not t.宽度 then
        t.宽度 = self.宽度
    end
    if not t.高度 then
        t.高度 = self.高度
    end
    return SDL窗口(t)
end
return SDL窗口
