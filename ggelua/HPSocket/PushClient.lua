-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 11:56:21

local HPS = require('HPSocket.HPSocket')

local PushClient = class('PushClient')

function PushClient:PushClient()
end

--描述：向指定连接发送 4096 KB 以下的小文件
function PushClient:发送小文件(dwConnID, lpszFileName, pHead, pTail)
    return self._hp:SendSmallFile(dwConnID, lpszFileName, pHead, pTail)
end
--/* 设置通信数据缓冲区大小（根据平均通信数据包大小调整设置，通常设置为：(N * 1024) - sizeof(TBufferObj)） */
function PushClient:置缓冲区大小(dwSocketBufferSize)
    self._hp:SetSocketBufferSize(dwSocketBufferSize)
    return self
end
--/* 设置正常心跳包间隔（毫秒，0 则不发送心跳包，默认：30 * 1000） */
function PushClient:置正常心跳间隔(dwKeepAliveTime)
    self._hp:SetKeepAliveTime(dwKeepAliveTime)
    return self
end
--/* 设置异常心跳包间隔（毫秒，0 不发送心跳包，，默认：10 * 1000，如果超过若干次 [默认：WinXP 5 次, Win7 10 次] 检测不到心跳确认包则认为已断线） */
function PushClient:置异常心跳间隔(dwKeepAliveInterval)
    self._hp:SetKeepAliveInterval(dwKeepAliveInterval)
    return self
end
--/* 获取通信数据缓冲区大小 */
function PushClient:取缓冲区大小()
    return self._hp:GetSocketBufferSize()
end
--/* 获取正常心跳包间隔 */
function PushClient:取正常心跳间隔()
    return self._hp:GetKeepAliveTime()
end
--/* 获取异常心跳包间隔 */
function PushClient:取异常心跳间隔()
    return self._hp:GetKeepAliveInterval()
end
--====================================================================================
--IClient
--====================================================================================
function PushClient:连接(lpszRemoteAddress, usPort, bAsyncConnect, lpszBindAddress, usLocalPort) --地址，端口，异步
    return self._hp:Start(lpszRemoteAddress, usPort, bAsyncConnect, lpszBindAddress, usLocalPort)
end

function PushClient:断开()
    return self._hp:Stop()
end

function PushClient:发送(...)
    return self._hp:Send(...)
end
-- --向指定连接发送多组数据
-- function PushClient:发送_组(pBuffers,iCount)
--     self._hp:SendPackets(pBuffers,iCount)
-- end
function PushClient:暂停接收(bPause)
    self._hp:PauseReceive(bPause)
    return self
end

function PushClient:等待(dwMilliseconds)
    self._hp:Wait(dwMilliseconds)
    return self
end

function PushClient:是否启动()
    return self._hp:HasStarted()
end
--  /* 查看通信组件当前状态 */
function PushClient:取状态()
    return HPS[self._hp:GetState()]
end

function PushClient:取错误代码()
    return self._hp:GetLastError()
end

function PushClient:取错误描述()
    return self._hp:GetLastErrorDesc()
end
--/* 获取该组件对象的连接 ID */
function PushClient:取连接ID()
    return self._hp:GetConnectionID()
end
--  /* 获取 Client Socket 的地址信息 */
function PushClient:取本地地址()
    return self._hp:GetLocalAddress()
end
--/* 获取连接的远程主机信息 */
function PushClient:取远程地址()
    return self._hp:GetRemoteHost()
end
--/* 获取连接中未发出数据的长度 */
function PushClient:取未发出数据长度()
    return self._hp:GetPendingDataLength()
end
--/* 获取连接的数据接收状态 */
function PushClient:是否暂停接收()
    return self._hp:IsPauseReceive()
end

function PushClient:是否连接()
    return self._hp:IsConnected()
end
-- RAP_NONE            不重用
-- RAP_ADDR_ONLY       仅重用地址
-- RAP_ADDR_AND_PORT   重用地址和端口
function PushClient:置地址重用策略(enReusePolicy)
    self._hp:SetReuseAddressPolicy(enReusePolicy)
    return self
end
--/* 设置内存块缓存池大小（通常设置为 -> PUSH 模型：5 - 10；PULL 模型：10 - 20 ） */
function PushClient:置缓存池大小(dwFreeBufferPoolSize)
    self._hp:SetFreeBufferPoolSize(dwFreeBufferPoolSize)
    return self
end
--/* 设置内存块缓存池回收阀值（通常设置为内存块缓存池大小的 3 倍） */
function PushClient:置缓存池回收阀值(dwFreeBufferPoolHold)
    self._hp:SetFreeBufferPoolHold(dwFreeBufferPoolHold)
    return self
end
--/* 获取地址重用选项 */
function PushClient:取地址重用策略()
    return self._hp:GetReuseAddressPolicy()
end
--/* 获取内存块缓存池大小 */
function PushClient:取缓存池大小()
    return self._hp:GetFreeBufferPoolSize()
end
--/* 获取内存块缓存池回收阀值 */
function PushClient:取缓存池回收阀值()
    return self._hp:GetFreeBufferPoolHold()
end
return PushClient
