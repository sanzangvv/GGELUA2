-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 12:09:24

local Astar = class('Astar')

function Astar:初始化(w, h, data)
    self._ud = require('gastar')(w, h, data)
    self._p = {}
    self.w = w
    self.h = h
end

function Astar:检查点(x, y)
    return self._ud:CheckPoint(x, y)
end

function Astar:寻路(x, y)
    return self._ud:GetPath(x, y)
end
return Astar
