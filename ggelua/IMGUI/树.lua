-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-11 22:09:20

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM树 = class('IM树', IM控件)

function IM树:初始化(name)
    self[1] = true
    self._name = name
end

function IM树:开始(name)
    return im.TreeNode(name or self._name)
end

function IM树:结束()
    im.TreePop()
end

function IM树:树叶(name)
    im.TreeNodeEx(name,256|8)--ImGuiTreeNodeFlags_Leaf
    return im.IsItemClicked()
end
return IM树
