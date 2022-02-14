-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 12:06:56

local HPS = require('HPSocket.HPSocket')

local UdpNode = class 'UdpNode'

function UdpNode:UdpNode()
    self._hp = require 'ghpsocket.udpnode'(self)
end

function UdpNode:OnReceive(lpszRemoteAddress, usRemotePort, pData) --数据到达
    if self.数据事件 then
        ggexpcall(self.数据事件, self, lpszRemoteAddress, usRemotePort, pData)
    end
    return 0
end
function UdpNode:OnPrepareListen(soListen)
    if self.准备事件 then
        ggexpcall(self.准备事件, self, soListen)
    end
    return 0
end
function UdpNode:OnSend(lpszRemoteAddress, usRemotePort, iLength)
    if self.发送事件 then
        ggexpcall(self.发送事件, self, lpszRemoteAddress, usRemotePort, iLength)
    end
    return 0
end
function UdpNode:OnError(enOperation, iErrorCode, lpszRemoteAddress, usRemotePort, pBuffer)
    if self.错误事件 then
        ggexpcall(self.错误事件, self, enOperation, iErrorCode, lpszRemoteAddress, usRemotePort, pBuffer)
    end
    return 0
end
function UdpNode:OnShutdown()
    if self.关闭事件 then
        ggexpcall(self.关闭事件, self)
    end
    return 0
end
--enCastMode
-- CM_UNICAST      // 单播
-- CM_MULTICAST    // 组播
-- CM_BROADCAST    // 广播
function UdpNode:启动(lpszBindAddress, usPort, enCastMode, lpszCastAddress)
    return self._hp:Start(lpszBindAddress, usPort, enCastMode, lpszCastAddress)
end
function UdpNode:停止()
    return self._hp:Stop()
end
function UdpNode:发送(lpszRemoteAddress, usRemotePort, pBuffer, iOffset)
    return self._hp:Send(lpszRemoteAddress, usRemotePort, pBuffer, iOffset)
end
function UdpNode:广播(pBuffer, iOffset)
    return self._hp:SendCast(pBuffer, iOffset)
end
function UdpNode:等待(dwMilliseconds)
    self._hp:Wait(dwMilliseconds)
end
function UdpNode:是否启动()
    return self._hp:HasStarted()
end
--  /* 查看通信组件当前状态 */
function UdpNode:取状态()
    return HPS[self._hp:GetState()]
end
--获取最近一次失败操作的错误代码
function UdpNode:取错误代码()
    return self._hp:GetLastError()
end
--获取最近一次失败操作的错误描述
function UdpNode:取错误描述()
    return self._hp:GetLastErrorDesc()
end
--  /* 获取本节点地址 */
function UdpNode:取本地地址()
    return self._hp:GetLocalAddress()
end
--/* 获取本节点传播地址 */
function UdpNode:取广播地址()
    return self._hp:GetCastAddress()
end
--  /* 获取传播模式 */
function UdpNode:取广播模式()
    return self._hp:GetCastMode()
end
--/* 获取连接中未发出数据的长度 */
function UdpNode:取未发出数据长度()
    return self._hp:GetPendingDataLength()
end
--/* 设置数据报文最大长度（建议在局域网环境下不超过 1472 字节，在广域网环境下不超过 548 字节） */
function UdpNode:置数据最大长度(dwMaxDatagramSize)
    self._hp:SetMaxDatagramSize(dwMaxDatagramSize)
    return self
end
--/* 获取数据报文最大长度 */
function UdpNode:取数据最大长度()
    return self._hp:GetMaxDatagramSize()
end
--  /* 设置组播报文的 TTL（0 - 255） */
function UdpNode:置组播TTL(iMCTtl)
    self._hp:SetMultiCastTtl(iMCTtl)
    return self
end
--  /* 获取组播报文的 TTL */
function UdpNode:取组播TTL()
    return self._hp:GetMultiCastTtl()
end
--  /* 设置是否启用组播环路（TRUE or FALSE） */
function UdpNode:置组播环路(bMCLoop)
    self._hp:SetMultiCastLoop(bMCLoop and 1 or 0)
end
--  /* 检测是否启用组播环路 */
function UdpNode:是否组播环路()
    return self._hp:IsMultiCastLoop() == 1
end
-- RAP_NONE            不重用
-- RAP_ADDR_ONLY       仅重用地址
-- RAP_ADDR_AND_PORT   重用地址和端口
function UdpNode:置地址重用策略(enReusePolicy)
    self._hp:SetReuseAddressPolicy(enReusePolicy)
    return self
end

--/* 设置工作线程数量（通常设置为 2 * CPU + 2） */
function UdpNode:置工作线程数量(dwWorkerThreadCount)
    self._hp:SetWorkerThreadCount(dwWorkerThreadCount)
    return self
end
--  /* 设置 Receive 预投递数量（根据负载调整设置，Receive 预投递数量越大则丢包概率越小） */
function UdpNode:置预投递数量(dwPostReceiveCount)
    self._hp:SetPostReceiveCount(dwPostReceiveCount)
    return self
end
--/* 设置内存块缓存池大小（通常设置为 -> PUSH 模型：5 - 10；PULL 模型：10 - 20 ） */
function UdpNode:置缓存池大小(dwFreeBufferPoolSize)
    self._hp:SetFreeBufferPoolSize(dwFreeBufferPoolSize)
    return self
end
--/* 设置内存块缓存池回收阀值（通常设置为内存块缓存池大小的 3 倍） */
function UdpNode:置缓存池回收阀值(dwFreeBufferPoolHold)
    self._hp:SetFreeBufferPoolHold(dwFreeBufferPoolHold)
    return self
end
--/* 获取地址重用选项 */
function UdpNode:取地址重用策略()
    return self._hp:GetReuseAddressPolicy()
end
--/* 获取工作线程数量 */
function UdpNode:取工作线程数量()
    return self._hp:GetWorkerThreadCount()
end
--/* 获取 Receive 预投递数量 */
function UdpNode:取预投递数量()
    return self._hp:GetPostReceiveCount()
end
--/* 获取内存块缓存池大小 */
function UdpNode:取缓存池大小()
    return self._hp:GetFreeBufferPoolSize()
end
--/* 获取内存块缓存池回收阀值 */
function UdpNode:取缓存池回收阀值()
    return self._hp:GetFreeBufferPoolHold()
end
return UdpNode
