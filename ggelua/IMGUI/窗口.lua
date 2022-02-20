-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:55:23

local ggf = require('GGE.函数')
local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM窗口 = class('IM窗口', IM控件)

function IM窗口:初始化(name, x, y, w, h)
    self._name = name .. '##' .. tostring(self)
    self._iswin = true
    self._flag = 64
    self.是否可见 = false
    if x and y then
        self._x = x
        self._y = y
    end
    if w and h then
        self._w = w
        self._h = h
    end
end

local flag =
    setmetatable(
    {
        禁止标题 = 1,
        禁止调整 = 2,
        禁止移动 = 4,
        禁止滑块 = 8,
        禁止滚动 = 16,
        禁止折叠 = 32,
        自动宽高 = 64,
        禁止背景 = 128,
        禁止保存 = 256,
        禁止鼠标 = 512,
        禁止菜单 = 1024
    },
    {__index = _G}
)
function IM窗口:__newindex(k, v)
    if k == '初始化' then
        ggf.setfenv(v, flag)
    end
    rawset(self, k, v)
end

function IM窗口:_更新(dt)
    if self.是否可见 then
        if self._x then
            im.SetNextWindowPos(self._x, self._y)
            self._x = nil
            self._y = nil
        end
        if self._w and self._h then
            im.SetNextWindowSize(self._w, self._h)
            self._w = nil
            self._h = nil
        end
        if im.Begin(self._name, self, self._flag) then
            self.是否可见 = self[1]
            IM控件._更新(self, dt)
            im.End()
        end
    end
end

function IM窗口:置可见(v, s)
    self[1] = v == true
    IM控件.置可见(self, v, s or not self.是否实例)
    return self
end

function IM窗口:折叠(b)
    --SetNextWindowCollapsed
    return self
end

function IM窗口:置样式(b)
    self._flag = b
    return self
end

function IM窗口:置坐标(x, y)
    self._x = x
    self._y = y
    return self
end

function IM窗口:取窗口坐标()
    return im.GetWindowPos()
end

function IM窗口:取窗口大小()
    return im.GetWindowSize()
end

function IM窗口:取窗口宽度()
    return im.GetWindowWidth()
end

function IM窗口:取窗口高度()
    return im.GetWindowHeight()
end
--==============================================================================
function IM控件:创建窗口(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM窗口(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

function IM控件:创建临时窗口(name, ...) --关闭将被删除
    local r = IM窗口(name, ...)
    table.insert(self._子控件, r)
    r._temp = true
    return r
end
--==============================================================================
local IM模态窗口 = class('IM模态窗口', IM控件)

function IM模态窗口:初始化(name)
    self._name = name
    self._flag = 64 | 256
end

function IM模态窗口:_更新()
    -- return im.BeginPopupModal(self._name,self,self._flag)
    -- return im.EndPopup()
end

--在开始 结束 之间使用
-- function IM模态窗口:关闭()
--     return im.CloseCurrentPopup()
-- end

-- function IM模态窗口:打开()
--     return im.OpenPopup(self._name)
-- end
return IM窗口
