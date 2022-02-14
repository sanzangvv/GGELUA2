-- @Author: baidwwy
-- @Date:   2021-08-18 13:24:54
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-12 09:30:58

local SDL = require 'SDL'
local GUI控件 = require('GUI.控件')

local GUI标签 = class('GUI标签', GUI控件)

function GUI标签:初始化()
    self._rect = {}
end

function GUI标签:置可见(...)
    GUI控件.置可见(self, ...)
    for _, b in ipairs(self.子控件) do
        if ggetype(b) == 'GUI单选按钮' and b.是否选中 then
            for k, v in pairs(self._rect) do
                v:置可见(k == b)
            end
            break
        end
    end
end

function GUI标签:创建区域(btn, x, y, w, h)
    local name = btn.名称 .. '区域'
    assert(not self[name], name .. ':此控件已存在，不能重复创建.')
    local r = GUI控件(name, x, y, w, h, self)
    table.insert(self.子控件, 1, r) --插到按钮前

    local 置选中 = btn.置选中
    btn.置选中 = function(this, v) --替换按钮选中事件
        if v then
            for k, v in pairs(self._rect) do
                v:置可见(k == btn)
            end
            置选中(this, v)
        end
    end
    self._rect[btn] = r
    self[name] = r
    return r
end

function GUI控件:创建标签(name, x, y, w, h)
    assert(not self[name], name .. ':此标签已存在，不能重复创建.')
    self[name] = GUI标签(name, x, y, w, h, self)
    table.insert(self.子控件, self[name])
    return self[name]
end

return GUI标签
