-- @Author: GGELUA
-- @Date:   2021-09-17 08:26:43
-- @Last Modified by    : GGELUA
-- @Last Modified time  : 2022-03-22 22:00:04

require 'SDL.精灵'

local GGE动画 = class('GGE动画')

function GGE动画:GGE动画(t, maxf, width, height, fps)
    if type(t) == 'table' then --载入器
        assert(type(t.取精灵) == 'function', '没有取精灵函数')
        assert(type(t.帧数) == 'number', '没有指定帧数')
        self.资源 = t
        self.FPS = t.帧率 or (1.0 / 8)
        self.帧数 = t.帧数
        self.宽度 = t.宽度
        self.高度 = t.高度
    elseif ggetype(t) == 'SDL纹理' then
        assert(type(maxf) == 'number', '没有指定帧数')
        assert(type(width) == 'number', '没有指定宽度')
        assert(type(height) == 'number', '没有指定高度')
        self.FPS = fps or (1.0 / 8)
        self.帧数 = maxf
        self.宽度 = width
        self.高度 = height
        local x, y = 0, 0
        for i = 1, maxf do
            self:添加帧(require 'SDL.精灵'(t, x, y, width, height))
            x = x + width
            if x + width > t:取宽度() then
                x = 0
                y = y + height
            end
        end
    end
    self.当前帧 = 0

    self._mode = 0 --1循环2往返
    self._delta = 1 --递增值
    self._list = {}
    self._load = {} --协程加载中
    self._dt = 0
    -- self._hx = 0
    -- self._hy = 0
end

function GGE动画:复制()
    local r = GGE动画()
    for k, v in pairs(self) do
        if type(v) ~= 'table' then
            r[k] = v
        end
    end
    r.资源 = self.资源
    for i, v in ipairs(self._list) do
        r._list[i] = v:复制()
    end
    return r
end

function GGE动画:更新(dt)
    if not self.是否播放 then
        return
    end
    self._dt = self._dt + dt

    if self._dt >= self.FPS then
        self._dt = self._dt - self.FPS
        local i = self.当前帧 + self._delta

        if i > self.帧数 then
            if self._mode & 1 == 1 then --循环
                if self._mode & 2 == 2 then --往返
                    self._delta = -self._delta
                else
                    self.当前帧 = 0
                end
            else
                self:暂停()
            end
        elseif i < 1 then
            if self._mode & 1 == 1 then --循环
                self._delta = 1
            else
                self:暂停()
            end
        end

        if self.是否播放 then
            self:置当前帧(self.当前帧 + self._delta)
        else
            return true
        end
    end
end

function GGE动画:置坐标(x, y)
    if not y and ggetype(x) == 'GGE坐标' then
        x, y = x:unpack()
    end
    if x and y then
        if self._hx then
            x, y = x - self._hx, y - self._hy
        end
        self._x, self._y = x, y
    end
end

function GGE动画:显示(x, y)
    if self._spr then
        self:置坐标(x, y)
        x, y = self._x, self._y
        local r = self._rect
        if r then
            引擎:置区域(x - r.x, y - r.y, r.w, r.h)
        end

        self._spr:显示(x, y)

        if r then
            引擎:置区域()
        end
    end
end

function GGE动画:播放(循环)
    self.是否播放 = true
    self.是否暂停 = false
    if 循环 ~= nil then
        self:置循环(循环)
    end
    local i = self.当前帧 + self._delta
    if i > self.帧数 then
        if self._mode & 2 == 2 then --往返
            self._delta = -1
        else
            self._delta = 1
            self:置当前帧(1)
        end
    elseif i < 1 then
        self._delta = 1
    end
    return self
end

local function _停止事件(self)
    if self.停止事件 then
        if type(self.停止事件) == 'function' then
            self.停止事件(self)
        elseif type(self.停止事件) == 'thread' then
            if coroutine.status(self.停止事件) == 'suspended' then
                coroutine.xpcall(self.停止事件)
            end
        end
    end
end

function GGE动画:停止()
    if not self.是否播放 then
        return
    end
    self:置首帧()
    self.是否播放 = false
    _停止事件(self)
    return self
end

function GGE动画:暂停()
    if not self.是否播放 then
        return
    end
    self.是否播放 = false
    self.是否暂停 = true
    _停止事件(self)
    return self
end

function GGE动画:恢复()
    self.是否播放 = true
    self.是否暂停 = false
    return self
end

function GGE动画:置往返(往返)
    self._mode = 往返 and (self._mode | 2) or (self._mode & ~2)
    return self
end

function GGE动画:置循环(循环)
    self._mode = 循环 and (self._mode | 1) or (self._mode & ~1)
    return self
end

function GGE动画:置帧率(v)
    assert(type(v) == 'number', '数据错误')
    self.FPS = v
    return self
end

function GGE动画:取帧率()
    return self.FPS
end

function GGE动画:取宽高()
    return self.宽度, self.高度
end

function GGE动画:置首帧()
    self._dt = 0
    self._delta = 1
    self:置当前帧(1)
    return self
end

function GGE动画:置尾帧()
    self._dt = 0
    self._delta = 1
    self:置当前帧(self.帧数)
    return self
end
--协程载入
local function _协程取精灵(self, i)
    self._load[i] = true
    local r = self.资源:取精灵(i)
    if self._load[i] and ggetype(r) == 'SDL精灵' then
        self._list[i] = r
        -- if self.资源.释放 and #self._list==self.帧数 then
        --     self.资源 = nil
        -- end
        self._load[i] = nil
    end
end

function GGE动画:置当前帧(i)
    if self.当前帧 ~= i and i > 0 and i <= self.帧数 then
        if not self._list[i] and self.资源 then
            if self.资源.协程 then
                if not self._load[i] then
                    coroutine.xpcall(_协程取精灵, self, i)
                end
            else
                local r = self.资源:取精灵(i)
                if ggetype(r) == 'SDL精灵' then
                    self._list[i] = r
                end
            end
        -- if self.资源.释放 and #self._list==self.帧数 then
        --     self.资源 = nil
        -- end
        end
        if self._list[i] then
            self.当前帧 = i
            self._spr = self._list[i]
            if self._r or self._g or self._b then
                self._spr:置颜色(self._r, self._g, self._b)
            end
            if self._a then
                self._spr:置透明(self._a)
            end
            if self._hl then
                self._spr:置高亮(self._hl)
            end
            if type(self.帧事件) == 'function' then
                self.帧事件(self, i, self.帧数)
            end
        end
    end
    return self
end

function GGE动画:添加帧(v)
    if ggetype(v) == 'SDL精灵' then
        table.insert(self._list, v)
    elseif ggetype(v) == 'SDL纹理' then
        table.insert(self._list, require 'SDL.精灵'(v))
    else
        error('不支持')
    end
    self.帧数 = #self._list
    return self
end

function GGE动画:删除帧(i)
    table.remove(self._list, i)
    return self
end

function GGE动画:取精灵(i)
    return i and self._list[i] or self._spr
end

function GGE动画:清空()
    self._dt = 0
    self.当前帧 = 0
    self._list = {}
    self._load = {}
    self._spr = nil
    return self
end

function GGE动画:置颜色(r, g, b, a)
    for k, v in pairs(self._list) do
        v:置颜色(r, g, b, a)
    end
    self._a = a
    self._r = r
    self._g = g
    self._b = b
    return self
end

function GGE动画:置透明(a)
    for k, v in pairs(self._list) do
        v:置透明(a)
    end
    self._a = a
    return self
end

function GGE动画:置高亮(r, g, b, a)
    for k, v in pairs(self._list) do
        v:置高亮(r, g, b, a)
    end
    self._hl = r
    return self
end

function GGE动画:取高亮()
    return self._spr and self._spr:取高亮()
end

function GGE动画:检查点(x, y)
    return self._spr and self._spr:检查点(x, y)
end

function GGE动画:取透明(x, y)
    return self._spr and self._spr:取透明(x, y)
end

function GGE动画:检查透明(x, y)
    return self._spr and self._spr:取透明(x, y) > 0
end

function GGE动画:置中心(x, y)
    self._hx = x or self._hx or 0
    self._hy = y or self._hy or 0
    return self
end

function GGE动画:取中心()
    return self._hx, self._hy
end

function GGE动画:取矩形()
    if self._spr then
        return self._spr:取矩形()
    end
    return require('SDL.矩形')()
end

function GGE动画:置区域(x, y, w, h)
    self._rect = require('GGE.矩形')(x, y, w, h)
    return self
end

return GGE动画
