-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-02 07:40:30

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM纹理 = class('IM纹理', IM控件)

function IM纹理:初始化()
end

function IM纹理:_更新(dt)
    if self._tex then
        im.Image(self._tex:取对象())
        IM控件._检查鼠标(self)
    end
    if self.更新 then
        self:更新(dt)
    end
end

function IM纹理:置纹理(tex)
    self._tex = tex
    return self
end
--==============================================================================
function IM控件:创建纹理(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM纹理(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end

return IM纹理
