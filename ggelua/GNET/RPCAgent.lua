-- @Author       : GGELUA
-- @Date         : 2021-09-17 08:26:43
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 11:57:22

local adler32 = require('zlib').adler32
local m_pack = require('cmsgpack').pack
local m_unpack = require('cmsgpack.safe').unpack

local c_isyieldable = coroutine.isyieldable
local c_runing = coroutine.running
local c_yield = coroutine.yield
local c_resume = coroutine.resume
local c_create = coroutine.create
local t_unpack = table.unpack
local PackAgent = require('HPSocket.PackAgent')
local RPCAgent = class('RPCAgent', PackAgent)

local _REG = setmetatable({}, {__mode = 'k'})
local _CBK = setmetatable({}, {__mode = 'k'})

function RPCAgent:RPCAgent()
    PackAgent.PackAgent(self) --初始化父类
    local reg = {}
    _REG[self] = reg --private
    _CBK[self] = {} --private

    return setmetatable(
        {},
        {
            __newindex = function(t, k, v)
                if type(v) == 'function' then
                    reg[k] = v
                    reg[adler32(k)] = v
                end
            end,
            __index = reg
        }
    )
end

function RPCAgent:__index(k) --调用方法
    local co, main = c_runing()
    local funp = type(k) == 'string' and adler32(k) or k
    if co and not main and c_isyieldable() then --如果有协程，则有返回值
        return function(self, id, ...)
            if id then
                local cop = adler32(tostring(co))
                _CBK[self][cop] = co
                self._hp:Send(id, m_pack {funp, cop, ...})
                return c_yield()
            end
        end
    end
    return function(self, id, ...)
        if id then
            self._hp:Send(id, m_pack {funp, 0, ...})
        end
    end
end

function RPCAgent:发送(id, ...)
    return self._hp:Send(id, m_pack {...})
end

local function cofunc(self, id, cop, func, ...)
    self._hp:Send(id, m_pack {0, cop, func(self, id, ...)})
end

function RPCAgent:_接收事件(id, data)
    if rawget(self, '接收事件') then
        self:接收事件(id, data)
        return
    end

    local t = m_unpack(data)
    if type(t) == 'table' then
        local funp, cop = t[1], t[2]
        if funp == 0 then --返回
            local co = _CBK[self][cop]
            if co then
                _CBK[self][cop] = nil
                coroutine.xpcall(co, t_unpack(t, 3))
            end
        else
            local func = _REG[self][funp]
            if func then
                if cop == 0 then --没有返回
                    func(self, id, t_unpack(t, 3))
                else
                    local r = coroutine.xpcall(cofunc, self, id, cop, func, t_unpack(t, 3))
                    if r == coroutine.FALSE then
                        self._hp:Send(id, m_pack {0, cop, nil})
                    end
                end
            elseif rawget(self, 'RPC事件') then --未注册的函数
                func = self.RPC事件
                if cop == 0 then --没有返回
                    func(self, id, funp, t_unpack(t, 3))
                else
                    local r = coroutine.xpcall(cofunc, self, id, cop, func, funp, t_unpack(t, 3))
                    if r == coroutine.FALSE then
                        self._hp:Send(id, m_pack {0, cop, nil})
                    end
                end
            elseif co ~= 0 then
                self._hp:Send(id, m_pack {0, cop, nil})
            end
        end
    end
end

return RPCAgent
