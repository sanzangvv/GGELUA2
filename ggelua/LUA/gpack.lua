-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-11-25 08:57:29

local mp_pack = require "cmsgpack".pack
local mp_unpack = require "cmsgpack".unpack

local function _en(nt,t)
    local r = {}
    for i,k in ipairs(nt) do
        if type(k) == 'table' then
            r[i] = _en(k,t[k.名称] or t)
        elseif type(k) == 'function' then
            r[i] = k(t)
        else
            r[i] = t[k]
        end
    end
    return r
end

local function _de(nt,t)
    local r = t
    for i,v in ipairs(nt) do
        if t[i]~=nil then
            if type(v) == 'table' then
                r[v.名称] = _de(v,t[i])
            elseif type(v)=='function' then
                local vk,vv = v(t[i])
                r[vk] = vv
            else
                r[v] = t[i]
            end
        end
    end
    return r
end

local meta = {__index={
    打包 = function (self,t)
        assert(type(t)=='table', 'table')
        local r = _en(self,t)
        return mp_pack(r)
    end,
    解包 = function (self,d)
        assert(type(d)=='string', 'string')
        local t = mp_unpack(d)
        return _de(self,t)
    end,
    打包列表 = function (self,t)
        assert(type(t)=='table', 'table')
        local r = {}
        for k,v in pairs(t) do
            r[k] = _en(self,v)
        end
        return mp_pack(r)
    end,
    解包列表 = function (self,d)
        assert(type(d)=='string', 'string')
        local t = mp_unpack(d)
        local r = {}
        for k,v in pairs(t) do
            r[k] = _de(self,v)
        end
        return r
    end,
}}

return function (t)
    assert(type(t)=='table', 'table')
    for _,v in pairs(t) do
        assert(type(v)=='table', 'table')
        setmetatable(v, meta)
    end
    return t
end
--[[
    local r = require"GGE封包"{
        登录属性 = {'气血','最大气血','上限气血','魔法','最大魔法','经验','升级经验','愤怒','最大愤怒',
        '名称','x','y','地图','方向','原形','外形','染色','称谓','性别','头像',
        '武器','rid','名称颜色','快捷键','GM'};
    }
    local pack = r.登录属性:打包(对象)
    local data = r.登录属性:解包(pack)
]]