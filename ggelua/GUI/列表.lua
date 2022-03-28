-- @Author: baidwwy
-- @Date:   2021-07-10 16:32:33
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-28 14:35:51

local SDL = require 'SDL'

local function _刷新焦点(self, x, y)
    local i, item = self:检查项目(x, y)
    if item then
        self.焦点行 = i
        return i, item
    else
        self.焦点行 = 0
    end
end

local function _滚动(self)
    local py = self._py
    for i, v in ipairs(self.子控件) do
        --列表之外不可见,以减少draw call
        local yy = py + v.y
        v.是否可见 = yy + v.高度 > 0 and yy < self.高度
        v:置中心(0, py)
    end

    _刷新焦点(self, self._win:取鼠标坐标())
end

local function _刷新列表(self)
    local hy, py = 0, self._py
    for i, v in ipairs(self.子控件) do
        v._i = i
        v.行号 = i
        v:置坐标(v.px, hy + v.py)
        local yy = py + v.y
        v.是否可见 = yy + v.高度 > 0 and yy < self.高度
        v:置中心(0, py)
        hy = hy + v.高度 + self.行间距
    end
    hy = hy - self.行间距
    if hy > self.高度 then --可以滚动的最大值
        self._max = hy - self.高度
    else
        self._max = 0
    end

    if self._max ~= 0 and self._auto then --自动滚动
        self._py = -self._max
        _滚动(self)
    end

    self:置选中(self.选中行)
    _刷新焦点(self, self._win:取鼠标坐标())
end

local GUI控件 = require('GUI.控件')
local GUI列表 = class('GUI列表', GUI控件)

do
    function GUI列表:初始化()
        self._py = 0 --滚动值
        self._max = 0 --滚动最大值

        self.行间距 = 0
        self.选中行 = 0
        self.焦点行 = 0

        self._文字 = self:取根控件()._文字:复制():置颜色(0, 0, 0, 255)

        self.行高度 = self._文字:取高度() + 1

        self.选中精灵 = require('SDL.精灵')(0, 0, 0, self.宽度, 0):置颜色(0, 0, 240, 128)
        self.焦点精灵 = require('SDL.精灵')(0, 0, 0, self.宽度, 0):置颜色(255, 255, 0, 128)
    end

    function GUI列表:_更新(dt)
        GUI控件._更新(self, dt)
        if self.选中精灵 and self.选中精灵.更新 then
            self.选中精灵:更新(dt)
        end
        if self.焦点精灵 and self.焦点精灵.更新 then
            self.焦点精灵:更新(dt)
        end
        if self._ref then
            self._ref = nil
            _刷新列表(self)
            if self._max ~= 0 and self._auto then --自动滚动
                self._py = -self._max
                _滚动(self)
            end
        end
    end

    function GUI列表:_显示(...)
        local _x, _y = self:取坐标()
        self._win:置区域(_x, _y, self.宽度, self.高度)
        if self.选中精灵 and self.选中行 > 0 and self.子控件[self.选中行] then
            local item = self.子控件[self.选中行]
            local x, y = item:取中心()
            self.选中精灵:置中心(-item.x, -(item.y + y))
            self.选中精灵:置区域(0, 0, item.宽度, item.高度)
            self.选中精灵:显示(_x, _y)
        end
        if self.焦点精灵 and self.焦点行 > 0 and self.子控件[self.焦点行] then
            local item = self.子控件[self.焦点行]
            local x, y = item:取中心()
            self.焦点精灵:置中心(-item.x, -(item.y + y))
            self.焦点精灵:置区域(0, 0, item.宽度, item.高度)
            self.焦点精灵:显示(_x, _y)
        end
        self._win:置区域()
        GUI控件._显示(self, ...)
    end

    function GUI列表:清空()
        self._py = 0 --滚动值
        self._max = 0 --滚动最大值
        self.选中行 = 0
        self.焦点行 = 0
        self.子控件 = {}
    end

    function GUI列表:添加(...)
        return self:插入(#self.子控件 + 1, ...)
    end

    local _列项 = class('GUI列项', GUI控件) --继承一下，防止控件接收掉消息
    function GUI列表:插入(i, 文本, x, y, w, h)
        local 列项 = _列项(文本, 0, 0, w or self.宽度, (h or self.行高度), self)
        列项.px = x or 0
        列项.py = y or 0
        if 文本 then
            列项:置精灵(self._文字:取精灵(文本))
        end

        if type(self.子显示) == 'function' then
            列项.显示 = function(this, x, y)
                self:子显示(x, y, this._i)
            end
        end
        local 置高度 = 列项.置高度
        列项.置高度 = function(this, v)
            置高度(this, v)
            self._ref = true
        end
        table.insert(self.子控件, i, 列项)
        self._ref = true
        return 列项
    end

    function GUI列表:删除(i)
        if self.子控件[i] then
            table.remove(self.子控件, i)
            self._ref = true
        end
    end

    function GUI列表:删除选中()
        local i = self.选中行
        if self.子控件[i] then
            table.remove(self.子控件, i)
            self._ref = true
        end
    end

    function GUI列表:自动删除(v)
        self._del = v
        return self
    end

    function GUI列表:定位(i)
    end

    function GUI列表:自动滚动(v)
        self._auto = v
        return self
    end

    function GUI列表:置高度(h)
        GUI控件.置高度(self, h)
        self._ref = true
        return self
    end

    function GUI列表:置宽度(w)
        GUI控件.置宽度(self, w)
        for i, v in ipairs(self.子控件) do
            v:置宽度(w)
        end
        --self._ref = true
        return self
    end

    function GUI列表:置宽高(w, h)
        GUI控件.置宽高(self, w, h)
        for i, v in ipairs(self.子控件) do
            v:置宽度(w)
        end
        self._ref = true
        return self
    end

    function GUI列表:取项目(i)
        if i < 0 then
            i = #self.子控件 + i + 1
        end
        return self.子控件[i]
    end

    function GUI列表:遍历项目()
        local 子控件 = {}
        for i, v in ipairs(self.子控件) do
            子控件[i] = v
        end
        return next, 子控件
    end

    function GUI列表:置文字(v)
        self._文字 = v
        self.行高度 = self._文字:取高度('A')
        return self
    end

    function GUI列表:置颜色(...)
        self._文字:置颜色(...)
        return self
    end

    function GUI列表:置项目颜色(i, ...)
        if self.子控件[i] and self.子控件[i]:取精灵() then
            self.子控件[i]:取精灵():置颜色(...)
        end
        return self
    end

    function GUI列表:置文本(i, v)
        if self.子控件[i] then
            self.子控件[i].名称 = v
            self.子控件[i]:置精灵(v and self._文字:取精灵(v))
        end
        return self
    end

    function GUI列表:取文本(i)
        return self.子控件[i] and self.子控件[i].名称
    end

    function GUI列表:取行数()
        return #self.子控件
    end

    function GUI列表:置选中(i)
        if self.子控件[i] then
            self.选中行 = i
        else
            self.选中行 = 0
        end
    end

    function GUI列表:取选中()
        if self.选中行 then
            return self.子控件[self.选中行]
        end
    end

    function GUI列表:检查项目(x, y)
        for i, item in ipairs(self.子控件) do
            if item.是否可见 and item:检查点(x, y) then
                return i, item
            end
        end
    end

    function GUI列表:向上滚动()
        if self._py < 0 then
            self._py = self._py + self.高度
            if self._py > 0 then
                self._py = 0
            end
            _滚动(self)
            return true
        end
    end

    function GUI列表:向下滚动()
        if math.abs(self._py) < self._max then
            self._py = self._py - self.高度
            if math.abs(self._py) > self._max then
                self._py = -self._max
            end
            _滚动(self)
            return self._py ~= -self._max
        end
    end

    function GUI列表:滚动到底()
        self._py = -self._max
        _滚动(self)
    end

    function GUI列表:是否到底()
        return self._py == -self._max
    end

    function GUI列表:绑定滑块(obj)
        self.滑块 = obj
        if obj then
            local 置位置 = obj.置位置
            obj.置位置 = function(this, v)
                置位置(this, v)
                self._py = -math.floor(this.位置 / this.最大值 * self._max)
                if self._py == 0 then
                    置位置(this, 0)
                end
                _滚动(self)
                return self._py ~= 0
            end
        end
        return obj
    end

    function GUI列表:创建滑块(name, x, y, w, h)
        local 滑块 = self.父控件:创建滑块(name, x, y, w, h)
        self:绑定滑块(滑块)
        return 滑块
    end

    function GUI列表:_消息事件(msg)
        if not self.是否可见 then
            return
        end
        GUI控件._消息事件(self, msg)

        if not msg.鼠标 then
            return
        end

        for _, v in ipairs(msg.鼠标) do
            if v.type == SDL.MOUSE_DOWN then
                if self:检查点(v.x, v.y) then
                    v.typed, v.type = v.type, nil
                    v.control = self

                    if not self.是否禁止 then
                        local i, item = self:检查项目(v.x, v.y)
                        if item then
                            self._curdown = i
                            if v.button == SDL.BUTTON_LEFT then
                                self.选中行 = i
                                if rawget(self, '左键按下') then
                                    local x, y = item:取坐标()
                                    self:发送消息('左键按下', x, y, i, item, msg)
                                end
                            elseif v.button == SDL.BUTTON_RIGHT then
                                if rawget(self, '右键按下') then
                                    local x, y = item:取坐标()
                                    self:发送消息('右键按下', x, y, i, item, msg)
                                end
                            end
                        end
                    end
                end
            elseif v.type == SDL.MOUSE_UP then
                if self:检查点(v.x, v.y) then
                    v.typed, v.type = v.type, nil
                    v.control = self

                    if not self.是否禁止 then
                        local i, item = self:检查项目(v.x, v.y)
                        if item and self._curdown == i then
                            if v.button == SDL.BUTTON_LEFT then
                                local x, y = item:取坐标()
                                if ggetype(self) == 'GUI树形列表' then
                                    if item.收展 then --有按钮
                                        item.收展:置选中(not item.是否展开)
                                    elseif item.是否节点 then
                                        item.是否展开 = not item.是否展开
                                        item.父控件._ref = true
                                    end
                                    item:发送消息('左键弹起', x, y, i, item, msg)
                                end
                                if rawget(self, '左键弹起') then
                                    self:发送消息('左键弹起', x, y, i, item, msg)
                                end
                                if v.clicks == 2 and rawget(self, '左键双击') then
                                    self:发送消息('左键双击', x, y, i, item, msg)
                                end
                            elseif v.button == SDL.BUTTON_RIGHT then
                                if rawget(self, '右键弹起') then
                                    local x, y = item:取坐标()
                                    self:发送消息('右键弹起', x, y, i, item, msg)
                                end
                            end
                        end
                    end
                end
            elseif v.type == SDL.MOUSE_MOTION then
                if self:检查点(v.x, v.y) then
                    v.typed, v.type = v.type, nil
                    v.control = self

                    local i, item = _刷新焦点(self, v.x, v.y)
                    if item then
                        local x, y = item:取坐标()
                        self:发送消息('获得鼠标', x, y, i, item, msg)
                    end
                else
                    self.焦点行 = 0
                end
            elseif v.type == SDL.MOUSE_WHEEL then
                local x, y = SDL._wins[v.windowID]:取鼠标坐标()
                if self:检查点(x, y) and self._max > 0 then
                    v.typed, v.type = v.type, nil
                    v.control = self
                    if not self.是否禁止 then
                        local py = self._py + v.y * (self.高度 / 2)

                        if py > 0 then
                            py = 0
                        end

                        if math.abs(py) > self._max then
                            py = -self._max
                        end

                        if self.滑块 then
                            self.滑块:置位置(math.floor(math.abs(py) / self._max * self.滑块.最大值))
                        else
                            self._py = math.floor(py)
                            _滚动(self)
                        end

                        self:发送消息('鼠标滚轮', py == -self._max)
                    end
                end
            end
        end
    end
end

function GUI控件:创建列表(name, x, y, w, h)
    assert(not self[name], name .. ':此列表已存在，不能重复创建.')
    self[name] = GUI列表(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end

--====================================================================
local function _刷新树(root, node)
    for _, v in ipairs(node) do
        table.insert(root.子控件, v)
        if v.是否展开 then --递归子项
            if v._node then
                _刷新树(root, v._node)
            end
        end
    end
end

local _节点 = class('树节点', GUI控件)
do
    function _节点:初始化(t, x, y, w, h, f)
        self.是否展开 = false
        self._lay = 1

        self.px = x or 0
        self.py = y or 0
        self:置精灵(f.文字:取精灵(t))
    end

    function _节点:添加(name, x, y)
        local r = _节点(name, self._lay * self.父控件.缩进宽度 + (x or 0), y, w or self.宽度, (h or self.父控件.行高度), self.父控件)
        r.父节点 = self
        r._lay = self._lay + 1

        if not self._node then
            self._node = {}
        end
        self.是否节点 = true
        table.insert(self._node, r)
        self.父控件._ref = true
        return r
    end

    function _节点:删除(name)
        if not self._node then
            return
        end
        for i, v in ipairs(self._node) do
            if v.名称 == name then
                table.remove(self._node, i)
                self.父控件._ref = true
                return
            end
        end
    end

    function _节点:清空()
        if not self._node then
            return
        end
        self._node = {}
        self.父控件._ref = true
    end

    function _节点:取项目(name)
        if not self._node then
            return
        end
        for i, v in ipairs(self._node) do
            if v.名称 == name then
                self.父控件._ref = true
                return v
            end
        end
    end

    function _节点:遍历项目()
        if not self._node then
            return next, {}
        end
        self.父控件._ref = true
        return next, self._node
    end

    function _节点:创建收展按钮(x, y, w, h)
        local 收展 = self:创建多选按钮('收展', x, y, w, h)
        收展.检查透明 = 收展.检查点
        function 收展.选中事件(_, b)
            self.是否展开 = b
            self.父控件._ref = true
        end

        if self:取精灵() then
            self:取精灵():置中心(-收展.宽度, 0)
        end
        return 收展
    end
end

--====================================================================
local GUI树形列表 = class('GUI树形列表', GUI列表)
do
    function GUI树形列表:初始化()
        self._node = {}
        self.缩进宽度 = 15
    end

    function GUI树形列表:添加(t, x, y)
        local r = _节点(t, x, y, (w or self.宽度), (h or self.行高度), self)

        table.insert(self._node, r)
        self._ref = true
        return r
    end

    function GUI树形列表:_更新(...)
        if self._ref then
            self.子控件 = {} --不使用清空
            _刷新树(self, self._node) --把节点添加到列表
            _刷新列表(self) --列表项目坐标刷新
            self._ref = nil --和GUI列表变量同名，可能会出现问题
        end
        GUI列表._更新(self, ...)
    end

    function GUI树形列表:清空()
        self._node = {}
        GUI列表.清空(self)
        self._ref = true
    end

    function GUI树形列表:取项目(name)
        for i, v in ipairs(self._node) do
            if v.名称 == name then
                self._ref = true
                return v
            end
        end
    end

    function GUI树形列表:遍历项目()
        self._ref = true
        return next, self._node
    end
end

function GUI控件:创建树形列表(name, x, y, w, h)
    assert(not self[name], name .. ':此树形列表已存在，不能重复创建.')
    self[name] = GUI树形列表(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end

--====================================================================
local GUI多列列表 = class('GUI多列列表', GUI列表)

do
    function GUI多列列表:初始化()
        self._info = {}
        self._color = ''
    end

    function GUI多列列表:添加列(x, y, w, h)
        local t = {x = x, y = y, w = w, h = h}
        table.insert(self._info, t)
        return t
    end

    function GUI多列列表:置颜色(r, g, b, a)
        self._color = string.format('#c%02X%02X%02X', r, g, b)
    end

    function GUI多列列表:添加(...)
        local data = {...}
        local 行 = GUI列表.添加(self)
        self[#self + 1] = 行
        for i, v in ipairs(self._info) do
            local 列 = 行:创建控件(i, v.x, v.y, v.w or 50, v.h or 行.高度)
            if data[i] then
                列.文本 = self._color .. tostring(data[i])
                列:创建文本(列.文本, 0, 0, 列.宽度, 列.高度):置文本(列.文本)
            end
        end
        return 行:置可见(true, true)
    end
end

function GUI控件:创建多列列表(name, x, y, w, h)
    assert(not self[name], name .. ':此多列列表已存在，不能重复创建.')
    self[name] = GUI多列列表(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end

return GUI列表
