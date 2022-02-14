-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-07 03:02:28

local _ENV = require('SDL')
local c_isyieldable = coroutine.isyieldable --lua5.3
local c_runing = coroutine.running
local c_yield = coroutine.yield
local GGE线程 = class 'GGE线程'

function GGE线程:GGE线程(code, name, ms)
    self._list = {}
    self._th = CreateThread(code, name or tostring(self), ms or 10, self._list)
end

function GGE线程:取名称()
    return self._th:GetThreadName()
end

function GGE线程:取ID()
    return self._th:GetThreadID()
end

function GGE线程:__index(k, super) --调用方法
    if GGE线程[k] then
        return
    end
    local co = c_runing()
    if co and c_isyieldable() then --如果有协程，则有返回值
        return function(self, ...)
            self._list[co] = {k, ...}
            return c_yield()
        end
    end
    return function(self, ...)
        table.insert(self._list, {k, ...})
    end
end

return GGE线程
