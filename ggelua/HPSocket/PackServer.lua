-- @Author: baidwwy
-- @Date:   2021-05-05 08:38:04
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 11:55:48

local HPS = require('HPSocket.HPSocket')
local Socket = require('HPSocket.Socket')
local PackServer = class('PackServer', Socket)
PackServer._hp = false
PackServer._准备事件 = false
PackServer._连接事件 = false
PackServer._发送事件 = false
PackServer._断开事件 = false
PackServer._停止事件 = false
PackServer._接收事件 = false
PackServer.准备事件 = false
PackServer.连接事件 = false
PackServer.发送事件 = false
PackServer.断开事件 = false
PackServer.停止事件 = false
PackServer.接收事件 = false

function PackServer:PackServer(Flag, Size)
    self._hp = require 'ghpsocket.packserver'(self)
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

--准备监听通知
function PackServer:OnPrepareListen(soListen)
    if self._准备事件 then
        ggexpcall(self._准备事件, self, soListen)
    elseif self.准备事件 then
        ggexpcall(self.准备事件, self, soListen)
    end
    return 0
end
--接收连接通知
function PackServer:OnAccept(dwConnID, soClient) --连接进入
    local ip, port = self._hp:GetRemoteAddress(dwConnID)
    if self._连接事件 then
        ggexpcall(self._连接事件, self, dwConnID, ip, port)
    elseif self.连接事件 then
        ggexpcall(self.连接事件, self, dwConnID, ip, port)
    end
    return 0
end
--已发送数据通知
function PackServer:OnSend(dwConnID, pData, iLength) --发送事件
    if self._发送事件 then
        ggexpcall(self._发送事件, self, pData, iLength)
    elseif self.发送事件 then
        ggexpcall(self.发送事件, self, pData, iLength)
    end
    return 1
end

function PackServer:OnClose(dwConnID, enOperation, iErrorCode) --连接退出
    if self._断开事件 then
        ggexpcall(self._断开事件, self, dwConnID, HPS[enOperation], iErrorCode)
    elseif self.断开事件 then
        ggexpcall(self.断开事件, self, dwConnID, HPS[enOperation], iErrorCode)
    end
    return 0
end
--关闭通信组件通知
function PackServer:OnShutdown()
    if self._停止事件 then
        ggexpcall(self._停止事件, self)
    elseif self.停止事件 then
        ggexpcall(self.停止事件, self)
    end
    return 0
end

function PackServer:OnReceive(dwConnID, pData) --数据到达
    if self._接收事件 then
        ggexpcall(self._接收事件, self, dwConnID, pData)
    elseif self.接收事件 then
        ggexpcall(self.接收事件, self, dwConnID, pData)
    end
    return 0
end

--====================================================================================
--IPackSocket
--====================================================================================
--/* 设置数据包最大长度（有效数据包最大长度不能超过 4194303/0x3FFFFF 字节，默认：262144/0x40000） */
function PackServer:置数据最大长度(dwMaxPackSize)
    assert(dwMaxPackSize <= 0x3FFFFF, '不符合范围')
    self._hp:SetMaxPackSize(dwMaxPackSize)
end
--/* 设置包头标识（有效包头标识取值范围 0 ~ 1023/0x3FF，当包头标识为 0 时不校验包头，默认：0） */
function PackServer:置包头标识(usPackHeaderFlag)
    assert(usPackHeaderFlag <= 0x3FF, '不符合范围')
    self._hp:SetPackHeaderFlag(usPackHeaderFlag)
end
--/* 获取数据包最大长度 */
function PackServer:取数据包最大长度()
    return self._hp:GetMaxPackSize()
end
--/* 获取包头标识 */
function PackServer:取包头标识()
    return self._hp:GetPackHeaderFlag()
end
--====================================================================================
--IPackServer
--====================================================================================
--描述：向指定连接发送 4096 KB 以下的小文件
function PackServer:发送小文件(dwConnID, lpszFileName, pHead, pTail)
    return self._hp:SendSmallFile(dwConnID, lpszFileName, pHead, pTail)
end
--  /* 设置 Accept 预投递数量（根据负载调整设置，Accept 预投递数量越大则支持的并发连接请求越多） */
function PackServer:置预投递数量(v)
    self._hp:SetAcceptSocketCount(v)
    return self
end
--  /* 设置通信数据缓冲区大小（根据平均通信数据包大小调整设置，通常设置为 1024 的倍数） */
function PackServer:置缓冲区大小(v)
    self._hp:SetSocketBufferSize(v)
    return self
end
--  /* 设置监听 Socket 的等候队列大小（根据并发连接数量调整设置） */
function PackServer:置等候队列大小(v)
    self._hp:SetSocketListenQueue(v)
    return self
end
--  /* 设置心跳包间隔（毫秒，0 则不发送心跳包） */
function PackServer:置正常心跳间隔(v)
    self._hp:SetKeepAliveTime(v)
    return self
end
--  /* 设置心跳确认包检测间隔（毫秒，0 不发送心跳包，如果超过若干次 [默认：WinXP 5 次, Win7 10 次] 检测不到心跳确认包则认为已断线） */
function PackServer:置异常心跳间隔(v)
    self._hp:SetKeepAliveInterval(v)
    return self
end
--  /* 获取 Accept 预投递数量 */
function PackServer:取预投递数量()
    return self._hp:GetAcceptSocketCount()
end
--  /* 获取通信数据缓冲区大小 */
function PackServer:取缓冲区大小()
    return self._hp:GetSocketBufferSize()
end
--  /* 获取监听 Socket 的等候队列大小 */
function PackServer:取等候队列大小()
    return self._hp:GetSocketListenQueue()
end
--  /* 获取正常心跳包间隔 */
function PackServer:取正常心跳间隔()
    return self._hp:GetKeepAliveTime()
end
--  /* 获取异常心跳包间隔 */
function PackServer:取异常心跳间隔()
    return self._hp:GetKeepAliveInterval()
end
--====================================================================================
--IServer
--====================================================================================
function PackServer:启动(ip, port) --IServer
    return self._hp:Start(ip, port)
end
--/* 获取监听 Socket 的地址信息 */
function PackServer:取监听地址() --IServer
    return self._hp:GetListenAddress()
end
return PackServer
