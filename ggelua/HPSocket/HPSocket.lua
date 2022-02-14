-- @Author       : GGELUA
-- @Date         : 2021-09-17 08:26:43
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-11-25 08:55:05

local string = string
local _ENV = require 'ghpsocket.hpsocket'

function 取版本()
    local v = GetHPSocketVersion()
    return string.format('%d.%d.%d.%d', v >> 24, v >> 16 & 255, v >> 8 & 255, v & 255)
end

function 取主机地址(host)
    return GetIPAddress(host)
end

function 枚举主机地址(host)
    return EnumHostIPAddresses(host)
end

SS_STARTING = '正在启动'
SS_STARTED = '已经启动'
SS_STOPPING = '正在停止'
SS_STOPPED = '已经停止'

SO_UNKNOWN = '未知'
SO_ACCEPT = '接受'
SO_CONNECT = '连接'
SO_SEND = '发送'
SO_RECEIVE = '接收'
SO_CLOSE = '关闭'
return _ENV
