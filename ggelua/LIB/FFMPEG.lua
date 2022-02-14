-- GGELUA
-- @Author: baidwwy
-- @Date:   2020-04-02 07:06:16
-- @Last Modified by:   baidwwy
-- @Last Modified time: 2021-01-24 18:50:05
assert(引擎, "未发现窗口",2)
local ffmpeg = require("gffmpeg")(引擎:取对象())

local GGE视频 = class("GGE视频")

function GGE视频:初始化(file)
    self._is = ffmpeg(file)
    self._eof = self._is==nil
end

function GGE视频:更新(dt)
    return not self._eof and self
end

function GGE视频:显示()
    if self._is and self._is:render() then
        self:关闭()
    end
end

function GGE视频:置宽高(w,h)

end

function GGE视频:关闭()
    if self._is then
        self._is:close()
    end
    self._is = nil
    self._eof = true
end

return GGE视频