-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-11 22:09:04

local im = require"gimgui"
local IM控件 = require 'IMGUI.控件'

local IM列表 = class('IM列表',IM控件)

function IM列表:初始化()
    self[1] = true

end

function IM列表:更新()

end
return IM列表