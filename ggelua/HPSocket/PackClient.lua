-- @Author: baidwwy
-- @Date:   2021-06-29 12:45:43
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 11:55:31

local HPS = require('HPSocket.HPSocket')
local PushClient = require('HPSocket.PushClient')
local PackClient = class('PackClient', PushClient)
PackClient._hp = false
PackClient._接收事件 = false
PackClient._准备事件 = false
PackClient._连接事件 = false
PackClient._发送事件 = false
PackClient._断开事件 = false
PackClient.接收事件 = false
PackClient.准备事件 = false
PackClient.连接事件 = false
PackClient.发送事件 = false
PackClient.断开事件 = false

function PackClient:PackClient(Flag, Size)
    self._hp = require 'ghpsocket.packclient'(self)

    if type(Flag) == 'number' and Flag <= 0x3FF then
        self._hp:SetPackHeaderFlag(Flag)
    else
        Flag = 0
        for _, v in ipairs {string.byte('GGELUA_FLAG', 1, #'GGELUA_FLAG')} do
            Flag = Flag + v
        end
        self._hp:SetPackHeaderFlag(Flag)
    end
    if type(Size) == 'number' and Size <= 0x3FFFFF then
        self._hp:SetMaxPackSize(Size)
    end
end

function PackClient:OnReceive(dwConnID, pData) --数据到达
    if self._接收事件 then
        ggexpcall(self._接收事件, self, pData)
    elseif self.接收事件 then
        ggexpcall(self.接收事件, self, pData)
    end
    return 0
end
--准备连接通知
function PackClient:OnPrepareConnect(dwConnID, socket)
    if self._准备事件 then
        ggexpcall(self._准备事件, self, socket)
    elseif self.准备事件 then
        ggexpcall(self.准备事件, self, socket)
    end
    return 0
end
--连接完成通知
function PackClient:OnConnect(dwConnID)
    if self._连接事件 then
        ggexpcall(self._连接事件, self)
    elseif self.连接事件 then
        ggexpcall(self.连接事件, self)
    end
    return 0
end
--已发送数据通知
function PackClient:OnSend(dwConnID, iLength)
    if self._发送事件 then
        ggexpcall(self._发送事件, self, iLength)
    elseif self.发送事件 then
        ggexpcall(self.发送事件, self, iLength)
    end
    return 1
end

function PackClient:OnClose(dwConnID, enOperation, iErrorCode)
    if self._断开事件 then
        ggexpcall(self._断开事件, self, HPS[enOperation], iErrorCode)
    elseif self.断开事件 then
        ggexpcall(self.断开事件, self, HPS[enOperation], iErrorCode)
    end
    return 0
end
--====================================================================================
--ITcpPackClient
--====================================================================================
--/* 设置数据包最大长度（有效数据包最大长度不能超过 4194303/0x3FFFFF 字节，默认：262144/0x40000） */
function PackClient:置数据最大长度(dwMaxPackSize)
    assert(dwMaxPackSize <= 0x3FFFFF, '不符合范围')
    self._hp:SetMaxPackSize(dwMaxPackSize)
    return self
end
--/* 设置包头标识（有效包头标识取值范围 0 ~ 1023/0x3FF，当包头标识为 0 时不校验包头，默认：0） */
function PackClient:置包头标识(usPackHeaderFlag)
    assert(usPackHeaderFlag <= 0x3FF, '不符合范围')
    self._hp:SetPackHeaderFlag(usPackHeaderFlag)
    return self
end
--/* 获取数据包最大长度 */
function PackClient:取数据包最大长度()
    return self._hp:GetMaxPackSize()
end
--/* 获取包头标识 */
function PackClient:取包头标识()
    return self._hp:GetPackHeaderFlag()
end

return PackClient
