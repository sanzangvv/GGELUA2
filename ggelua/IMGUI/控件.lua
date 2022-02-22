-- @Author       : GGELUA
-- @Date         : 2021-12-11 01:01:03
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 17:22:04

local im = require 'gimgui'
local IM控件 = class('IM控件')

function IM控件:初始化(name, x, y, w, h)
    self.名称 = name and tostring(name) or nil
    self.x = math.floor(tonumber(x) or 0)
    self.y = math.floor(tonumber(y) or 0)
    self.宽度 = w
    self.高度 = h

    self._子控件 = {}
    self.是否可见 = true
end

function IM控件:_更新(...)
    for _, v in ipairs(self._子控件) do
        if v.是否可见 then
            if v.是否禁止 then
                im.BeginDisabled(true)
            end
            v:_更新(...)
            if v.是否禁止 then
                im.EndDisabled()
            end
            if v.更新 then
                v:更新(...)
            end
        end
    end
    for i, v in ipairs(self._子控件) do
        if not v.是否可见 and v._temp then
            table.remove(self._子控件, i)
            break
        end
    end
end

function IM控件:_检查鼠标()
    if im.IsItemHovered() then
        if self._tip then
            im.SetTooltip(self._tip)
        end
        self:发送消息('焦点事件')
    end
    if im.IsItemClicked() then
        self:发送消息('左键事件')
        if im.IsMouseDoubleClicked() then
            self:发送消息('左键双击事件')
        end
    end
    if im.IsItemClicked(1) then
        self:发送消息('右键事件')
        if im.IsMouseDoubleClicked(1) then
            self:发送消息('右键双击事件')
        end
    end
end

function IM控件:置可见(val, sub)
    if val and self.是否实例 and self.是否禁止 then
        return self
    end
    if self._lock then
        self.是否可见 = val == true
        return
    end
    self._lock = true
    if self:发送消息('可见事件', val) == false then
        return self
    end
    self.是否可见 = val == true

    if not self.是否实例 and val then
        if rawget(self, '初始化') then
            ggexpcall(self.初始化, self)
        end
        self.是否实例 = true
    end
    if sub then
        for _, v in ipairs(self._子控件) do
            if v.置可见 then
                v:置可见(val, sub)
            end
        end
    end
    self._lock = nil
    return self
end

function IM控件:置禁止(v)
    self.是否禁止 = v == true
    return self
end

function IM控件:发送消息(name, ...)
    local fun = rawget(self, name)
    if type(fun) == 'function' then
        return coroutine.xpcall(fun, self, ...)
    end
end

local 同行 = {
    是否可见 = true,
    _更新 = function()
        im.SameLine()
    end
}
function IM控件:同行()
    table.insert(self._子控件, 同行)
    return self
end

local 对齐 = {
    是否可见 = true,
    _更新 = function()
        im.AlignTextToFramePadding()
    end
}
function IM控件:对齐()
    table.insert(self._子控件, 对齐)
    return self
end

local 分隔线 = {
    是否可见 = true,
    _更新 = function()
        im.Separator()
    end
}
function IM控件:分隔线()
    table.insert(self._子控件, 分隔线)
    return self
end

function IM控件:置提示(v)
    self._tip = v
end

function IM控件:创建控件(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM控件(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

function IM控件:删除控件(name)
    for i, v in ipairs(self._子控件) do
        if v == self[name] then
            table.remove(self._子控件, i)
            self[name] = nil
            return true
        end
    end
end

function IM控件:清空控件()
end
--==============================================================================
local IM选项 = class('IM选项', IM控件)
do
    function IM选项:初始化()
        self._flag = 2 | 4
        self.是否选中 = false
    end

    function IM选项:_更新()
        if im.Selectable(self.名称, self.是否选中, self._flag) then
            self:发送消息('选中事件', self.是否选中)
            if im.IsMouseDoubleClicked() then --ImGuiMouseButton_Left flag = 4
                self:发送消息('双击事件')
            end
        end
        IM控件._更新(self)
    end

    function IM选项:置选中(b)
        self.是否选中 = b == true
    end
end
--==============================================================================
function IM控件:创建选项(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM选项(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

-- function IMBase:是否按下(b)
--     return im.IsMouseDown(b)
-- end

-- function IMBase:是否弹起(b)
--     return im.IsMouseReleased(b)
-- end

-- function IMBase:是否单击(b,r)
--     return im.IsMouseClicked(b,r)
-- end
return IM控件
