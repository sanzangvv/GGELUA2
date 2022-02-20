-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:35:47
local GGF = require('GGE.函数')
local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM树 = class('IM树', IM控件)

function IM树:初始化(name)
    self._name = name .. '##' .. tostring(self) --避免重复
    self._tp = 1
end

function IM树:_更新()
    if self._tp == 1 then
        if self._open ~= nil then
            im.SetNextItemOpen(self._open)
            self._open = nil
        end
        if im.TreeNode(self._name) then
            IM控件._更新(self)
            im.TreePop()
        end
    elseif self._tp == 2 then
        im.TreeNodeEx(self._name, 8 | 256 | 512) --ImGuiTreeNodeFlags_NoTreePushOnOpen|ImGuiTreeNodeFlags_Leaf|ImGuiTreeNodeFlags_Bullet
        IM控件._检查鼠标(self)
    end
end

function IM树:添加(path)
    local list = GGF.分割文本(path:gsub('\\', '/'), '/')
    local file = table.remove(list)
    local tree = self
    for _, v in ipairs(list) do
        if tree[v] then
            tree = tree[v]
        else
            tree = tree:创建树(v)
        end
    end
    local leaf = tree:创建树叶(file)
    leaf._path = path
    return leaf
end

IM树.清空 = IM树.清空控件

function IM树:展开(v)
    self._open = v == true
    return self
end
--==============================================================================
function IM控件:创建树(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM树(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

function IM控件:创建树叶(name, ...)
    local r = IM树(name, ...)
    r._tp = 2
    table.insert(self._子控件, r)
    return r
end

return IM树
