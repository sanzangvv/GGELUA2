-- @Author: baidwwy
-- @Date:   2021-08-18 13:24:54
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-17 02:42:07

local GUI列表 = require('GUI.列表')
local GUI控件 = require('GUI.控件')
local GUI组合 = class('GUI组合', GUI控件)

function GUI组合:初始化(_, x, y, w, h)
    self:创建文本(0, 0, w, h)

    self.文字 = self:取根控件()._文字:复制()
    self.文字:置颜色(0, 0, 0, 255)
end

function GUI组合:检查点()--子控件在组合之外，虽然父检查通过
    return true
end

function GUI组合:置颜色(...)
    self.文字:置颜色(...)
end

function GUI组合:置文本(s)
    self.选中项 = s
    if self.文本 then
        self.文本:置精灵(self.文字:取精灵(self.选中项))
    else
        self.输入:置文本(self.选中项)
    end
end

function GUI组合:取文本()
    if self.文本 then
        return self.选中项
    elseif self.输入 then
        return self.输入:取文本()
    end
    return ''
end

function GUI组合:取数值()
    if self.文本 then
        return tonumber(self.选中项)
    elseif self.输入 then
        return self.输入:取数值()
    end
    return ''
end

function GUI组合:添加(t)
    if self.列表 then
        return self.列表:添加(t)
    end
end

function GUI组合:创建文本(x, y, w, h)
    self:删除控件('文本')
    self:删除控件('输入')
    self.文本 = GUI控件.创建文本(self, '文本', x, y, w, h)
    return self.文本
end

function GUI组合:创建输入(x, y, w, h)
    self:删除控件('文本')
    self:删除控件('输入')
    self.输入 = GUI控件.创建输入(self, '输入', x, y, w, h)
    return self.输入
end

function GUI组合:创建按钮(x, y)
    local 按钮 = GUI控件.创建按钮(self, '按钮', x, y)
    function 按钮.左键弹起()
        if self.列表控件 then
            self.列表控件:置可见(true)
        end
    end
    return 按钮
end

function GUI组合:创建列表(x, y, w, h)
    local 控件 = GUI控件.创建弹出控件(self, '控件', x, y, w, h)
    local 列表 = 控件:创建列表('列表', 0, 0, w, h)

    function 列表.左键弹起()
        self:置文本(列表:取文本(列表.选中行))
        控件:置可见(false)
    end
    self.列表 = 列表
    self.列表控件 = 控件
    return 列表
end

function GUI控件:创建组合(name, x, y, w, h)
    assert(not self[name], name .. ':此组合已存在，不能重复创建.')
    self[name] = GUI组合(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end
return GUI组合
