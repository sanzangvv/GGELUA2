-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-13 22:54:00

local im = require"gimgui"
local IM控件 = require 'IMGUI.控件'

local IM纹理 = class('IM纹理',IM控件)

function IM纹理:初始化(t)
    self[1] = true
    self._tex = t
end

function IM纹理:更新()
    im.Image(ptr)
    IM控件.更新_(self)
end

return IM纹理