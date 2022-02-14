-- @Author       : GGELUA
-- @Date         : 2021-12-11 01:01:03
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-13 22:54:47

local im = require 'gimgui'
local IM控件 = class('IM控件')

function IM控件:初始化(name, w, h, x, y)
    self.名称 = name and tostring(name) or nil
    self.x = math.floor(tonumber(x) or 0)
    self.y = math.floor(tonumber(y) or 0)
    self.宽度 = w
    self.高度 = h

    self._子控件 = {}
end

function IM控件:__index(k)
    if k == '是否可见' then
        return self[1]
    end
end

function IM控件:更新(...)
    for _, v in ipairs(self._子控件) do
        if v[1] then
            v:更新(...)
        end
    end
end

function IM控件:_更新()
    if self._iswin then
    else
    end
    -- if self._nw then
    --     im.SetNextItemWidth(self._nw)
    --     self._nw = nil
    -- end
    -- if self._open then
    --     self._open = nil
    --     im.SetNextItemOpen(true)
    -- end
end

function IM控件:更新_()
    if self._tip and im.IsItemHovered() then
        im.SetTooltip(self._tip)
    end
end

function IM控件:置可见(val, sub)
    if val and self.是否实例 and self.是否禁止 then
        return self
    end
    if self._lock then
        self[1] = val == true
        return
    end
    self._lock = true
    if self:发送消息('可见事件', val) == false then
        return self
    end
    self[1] = val == true

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
    [1] = true,
    更新 = function()
        im.SameLine()
    end
}
function IM控件:同行()
    table.insert(self._子控件, 同行)
    return self
end

local 对齐 = {
    [1] = true,
    更新 = function()
        im.AlignTextToFramePadding()
    end
}
function IM控件:对齐()
    table.insert(self._子控件, 对齐)
    return self
end

local 分隔线 = {
    [1] = true,
    更新 = function()
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
    assert(not self[name], name .. ':此控件已存在，不能重复创建.')
    self[name] = IM控件(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

local IM选项 = class('IM选项',IM控件)
function IM选项:初始化()
    self._flag = 2|4
    self.是否选中 = false
    self[1] = true
end

function IM选项:更新()
    if im.Selectable(self.名称,self.是否选中,self._flag) then
        self:发送消息('选中事件',self.是否选中)
        if im.IsMouseDoubleClicked() then --ImGuiMouseButton_Left flag = 4
            self:发送消息('双击事件')
        end
    end
    IM控件.更新(self)
end

function IM选项:置选中(b)
    self.是否选中 = b==true
end

function IM控件:创建选项(name, ...)
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
