-- @Author       : GGELUA
-- @Date         : 2021-09-17 08:26:43
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-16 14:55:37

local adler32 = require('zlib').adler32
local m_pack = require('cmsgpack').pack
local m_unpack = require('cmsgpack.safe').unpack

local c_isyieldable = coroutine.isyieldable --lua5.3
local c_runing = coroutine.running
local c_yield = coroutine.yield
local c_resume = coroutine.resume
local c_create = coroutine.create
local t_unpack = table.unpack
local next = next
local PackClient = require('HPSocket.PackClient')
local RPCClient = class('RPCClient', PackClient)

local _REG = setmetatable({}, {__mode = 'k'})
local _CBK = setmetatable({}, {__mode = 'k'})

function RPCClient:RPCClient(mcall)
    if mcall and 引擎 then --用主线程回调数据
        self._mdata = {}

        引擎:注册事件(
            self,
            {
                更新事件 = function()
                    if next(self._mdata) then
                        for _, v in ipairs(self._mdata) do
                            self:_接收事件(v, true)
                        end
                        self._mdata = {}
                    end
                end
            }
        )
    end
    PackClient.PackClient(self) --初始化父类
    local reg = {}
    _REG[self] = reg --private  注册表
    _CBK[self] = {} --private  回调表
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

function RPCClient:__index(k) --调用方法
    local co, main = c_runing()
    local funp = type(k) == 'string' and adler32(k) or k
    if co and not main and c_isyieldable() then --如果有协程，则有返回值
        return function(self, ...)
            local cp = adler32(tostring(co))
            _CBK[self][cp] = co --TODO:超时
            self._hp:Send(m_pack {funp, cp, ...})
            return c_yield()
        end
    end
    return function(self, ...)
        self._hp:Send(m_pack {funp, 0, ...})
    end
end

function RPCClient:发送(...)
    return self._hp:Send(m_pack {...})
end

local function cofunc(self, cop, func, ...)
    self._hp:Send(m_pack {0, cop, func(self, ...)})
end

function RPCClient:_接收事件(data, mc)
    if rawget(self, '接收事件') then
        self:接收事件(data)
        return
    end
    if rawget(self, '_mdata') and not mc then
        table.insert(self._mdata, data)
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
                    func(self, t_unpack(t, 3))
                else
                    local r = coroutine.xpcall(cofunc, self, cop, func, t_unpack(t, 3))
                    if r == coroutine.FALSE then
                        self._hp:Send(m_pack {0, cop, nil})
                    end
                end
            elseif rawget(self, 'RPC事件') then --未注册的函数
                func = self.RPC事件
                if cop == 0 then --没有返回
                    func(self, funp, t_unpack(t, 3))
                else
                    local r = coroutine.xpcall(cofunc, self, cop, func, funp, t_unpack(t, 3))
                    if r == coroutine.FALSE then
                        self._hp:Send(m_pack {0, cop, nil})
                    end
                end
            elseif cop ~= 0 then
                self._hp:Send(m_pack {0, cop, nil})
            end
        end
    end
end

return RPCClient
