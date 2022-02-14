-- @Author       : GGELUA
-- @Date         : 2021-09-17 08:26:43
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 12:04:37

local adler32 = require('zlib').adler32
local m_pack = require('cmsgpack').pack
local m_unpack = require('cmsgpack.safe').unpack

local c_isyieldable = coroutine.isyieldable
local c_runing = coroutine.running
local c_yield = coroutine.yield
local c_resume = coroutine.resume
local c_create = coroutine.create
local t_unpack = table.unpack

local PackServer = require('HPSocket.PackServer')
local RPCServer = class('RPCServer', PackServer)

local _REG = setmetatable({}, {__mode = 'k'}) --接收函数
local _CBK = setmetatable({}, {__mode = 'k'}) --等待返回的协程
local _PAS = setmetatable({}, {__mode = 'k'}) --验证连接

function RPCServer:RPCServer()
    PackServer.PackServer(self) --初始化父类
    local reg = {}
    _REG[self] = reg --private
    _CBK[self] = {} --private
    _PAS[self] = {}
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

function RPCServer:__index(k) --调用方法
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

function RPCServer:发送(id, ...)
    return self._hp:Send(id, m_pack {...})
end

function RPCServer:_连接事件(id, ip, port)
    _PAS[self][id] = true
    if self.连接事件 then
        local r = ggexpcall(self.连接事件, self, id, ip, port)
        _PAS[self][id] = r ~= false
    end
end

local function cofunc(self, id, cop, func, ...)
    self._hp:Send(id, m_pack {0, cop, func(self, id, ...)})
end

function RPCServer:_接收事件(id, data)
    if rawget(self, '接收事件') then
        self:接收事件(id, data)
        return
    end

    local t = m_unpack(data)
    if type(t) ~= 'table' then
        return
    end

    if _PAS[self][id] then
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
            elseif cop ~= 0 then
                self._hp:Send(id, m_pack {0, cop, nil})
            end
        end
    elseif rawget(self, '验证事件') then
        local funp, cop = t[1], t[2]
        if funp == 261030967 then --adler32('验证')
            local r = self:验证事件(id, t_unpack(t, 3))
            self._hp:Send(id, m_pack {0, cop, r})
            if r then
                _PAS[self][id] = true
            else
                self:断开(id)
            end
        end
    end
end

return RPCServer
