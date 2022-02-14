-- @Author: baidwwy
-- @Date:   2021-05-05 08:38:04
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 11:54:37

local HPS = require('HPSocket.HPSocket')
local PushClient = require('HPSocket.PushClient')
local HttpClient = class('HttpClient', PushClient)

function HttpClient:HttpClient()
    self._hp = require 'ghpsocket.httpclient'(self)
end

function HttpClient:OnReceive(dwConnID, pData) --数据到达
    if self._接收事件 then
        ggexpcall(self._接收事件, self, dwConnID, pData)
    elseif self.接收事件 then
        ggexpcall(self.接收事件, self, dwConnID, pData)
    end
    return 0
end

--连接完成通知
function HttpClient:OnConnect(dwConnID)
    if self._连接事件 then
        ggexpcall(self._连接事件, self, dwConnID)
    elseif self.连接事件 then
        ggexpcall(self.连接事件, self, dwConnID)
    end
    return 0
end
--已发送数据通知
function HttpClient:OnSend(dwConnID, iLength)
    if self._发送事件 then
        ggexpcall(self._发送事件, self, dwConnID, iLength)
    elseif self.发送事件 then
        ggexpcall(self.发送事件, self, dwConnID, iLength)
    end
    return 1
end

function HttpClient:OnClose(dwConnID, enOperation, iErrorCode)
    if self._断开事件 then
        ggexpcall(self._断开事件, self, dwConnID, HPS[enOperation], iErrorCode)
    elseif self.断开事件 then
        ggexpcall(self.断开事件, self, dwConnID, HPS[enOperation], iErrorCode)
    end
    return 0
end
--开始解析 HTTP 报文时，向监听器发送该通知
function HttpClient:OnMessageBegin(dwConnID)
    --print('OnMessageBegin',dwConnID)
    if self.开始事件 then
        ggexpcall(self.开始事件, self, dwConnID)
    end
    return 0
end

function HttpClient:OnRequestLine(OnRequestLine)
    return 0
end
--状态行解析完成后，向监听器发送该通知
function HttpClient:OnStatusLine(dwConnID, usStatusCode, lpszDesc)
    --print('OnStatusLine',dwConnID,usStatusCode,lpszDesc)
    if self._co then
        if usStatusCode ~= 200 then
            local co = self._co
            self:断开()
            self._co = nil
            self._data = nil
            coroutine.xpcall(co, nil, usStatusCode, lpszDesc)
        end
    elseif self.状态事件 then
        ggexpcall(self.状态事件, self, dwConnID, usStatusCode, lpszDesc)
    end
    return 0
end
--每当解析完成一个请求头后，向监听器发送该通知
function HttpClient:OnHeader(dwConnID, lpszName, lpszValue)
    --print('OnHeader',dwConnID,lpszName,lpszValue)
    if self._co then
        if lpszName == 'Content-Length' then
            self._len = lpszValue
        end
    elseif self.报头事件 then
        ggexpcall(self.报头事件, self, dwConnID, lpszName, lpszValue)
    end
    return 0
end
--解析完成所有请求头后，向监听器发送该通知
function HttpClient:OnHeadersComplete(dwConnID)
    --print('OnHeadersComplete',dwConnID)
    if self.报头事件 then
        ggexpcall(self.报头事件, self, dwConnID)
    end
    return 0
end
--每当接收到 HTTP BODY 报文，向监听器发送该通知
function HttpClient:OnBody(dwConnID, pData)
    --print('OnBody',dwConnID,#pData)
    if self._co then
        self._data = self._data .. pData
        if self.进度事件 and self._len then
            ggexpcall(self.进度事件, self, #self._data / self._len)
        end
    elseif self.报文事件 then
        ggexpcall(self.报文事件, self, dwConnID, pData)
    end
    return 0
end
--每当解析出一个 Chunked 报文头，向监听器发送该通知
function HttpClient:OnChunkHeader(dwConnID, iLength)
    --print('OnChunkHeader',dwConnID,iLength)
    return 0
end
--每当解析完一个 Chunked 报文，向监听器发送该通知
function HttpClient:OnChunkComplete(dwConnID)
    --print('OnChunkComplete',dwConnID)
    return 0
end
--每当解析完成一个完整 HTTP 报文，向监听器发送该通知
function HttpClient:OnMessageComplete(dwConnID)
    --print('OnMessageComplete',#self._data)
    if self._co then
        local co, data = self._co, self._data
        self._co = nil
        self._data = nil
        coroutine.xpcall(co, data)
    elseif self.结束事件 then
        ggexpcall(self.结束事件, self, dwConnID)
    end
    return 0
end

function HttpClient:OnUpgrade(dwConnID, enUpgradeType)
    return 0
end
--当解析 HTTP 报文错误时，向监听器发送该通知
function HttpClient:OnParseError(dwConnID, iErrorCode, lpszErrorDesc)
    --print('OnParseError',dwConnID,iErrorCode,lpszErrorDesc)
    if self.错误事件 then
        ggexpcall(self.错误事件, self, dwConnID, iErrorCode, lpszErrorDesc)
    end
    return 0
end

function HttpClient:OnWSMessageHeader(dwConnID, bFinal, iReserved, iOperationCode, lpszMask, ullBodyLen)
end

function HttpClient:OnWSMessageBody(dwConnID, pData)
end

function HttpClient:OnWSMessageComplete(dwConnID)
end

function HttpClient:请求(lpszMethod, lpszPath, lpHeaders, pBody)
    return self._hp:SendRequest(lpszMethod, lpszPath, lpHeaders, pBody)
end

function HttpClient:POST(lpszPath, lpHeaders, pBody)
    return self._hp:SendRequest('POST', lpszPath, lpHeaders, pBody)
end

function HttpClient:PUT(lpszPath, lpHeaders, pBody)
    return self._hp:SendRequest('PUT', lpszPath, lpHeaders, pBody)
end

function HttpClient:PATCH(lpszPath, lpHeaders, pBody)
    return self._hp:SendRequest('PATCH', lpszPath, lpHeaders, pBody)
end

function HttpClient:GET(lpszPath, lpHeaders)
    if self._hp:SendRequest('GET', lpszPath, lpHeaders) then
        if coroutine.isyieldable() then
            self._co = coroutine.running()
            self._data = ''
            return coroutine.yield()
        end
    end
end

function HttpClient:DELETE(lpszPath, lpHeaders)
    return self._hp:SendRequest('DELETE', lpszPath, lpHeaders)
end

function HttpClient:HEAD(lpszPath, lpHeaders)
    return self._hp:SendRequest('HEAD', lpszPath, lpHeaders)
end

function HttpClient:TRACE(lpszPath, lpHeaders)
    return self._hp:SendRequest('TRACE', lpszPath, lpHeaders)
end

function HttpClient:OPTIONS(lpszPath, lpHeaders)
    return self._hp:SendRequest('OPTIONS', lpszPath, lpHeaders)
end

function HttpClient:CONNECT(lpszPath, lpHeaders)
    return self._hp:SendRequest('CONNECT', lpszPath, lpHeaders)
end
--/* 设置是否使用 Cookie（默认：TRUE） */
function HttpClient:置Cookie(bUseCookie)
    self._hp:SetUseCookie(bUseCookie)
end
--/* 检查是否使用 Cookie */
function HttpClient:是否使用Cookie(lpszPath, lpHeaders)
    return self._hp:IsUseCookie()
end
--SendWSMessage
function HttpClient:启动()
    return self._hp:StartHttp()
end
--SendChunkData
--/* 设置本地协议版本 */
function HttpClient:置本地协议版本()
    self._hp:SetLocalVersion()
end
--/* 获取本地协议版本 */
function HttpClient:取本地协议版本()
    return self._hp:GetLocalVersion()
end
--/* 检查是否升级协议 */
function HttpClient:是否升级协议()
    return self._hp:IsUpgrade()
end
--/* 检查是否有 Keep-Alive 标识 */
function HttpClient:是否KeepAlive()
    return self._hp:IsKeepAlive()
end
--/* 获取协议版本 */
function HttpClient:取协议版本()
    return self._hp:GetVersion()
end
--/* 获取内容长度 */
function HttpClient:取内容长度()
    return self._hp:GetContentLength()
end
--/* 获取内容类型 */
function HttpClient:取内容类型()
    return self._hp:GetContentType()
end
--/* 获取内容编码 */
function HttpClient:取内容编码()
    return self._hp:GetContentEncoding()
end
--/* 获取传输编码 */
function HttpClient:取传输编码()
    return self._hp:GetTransferEncoding()
end
--/* 获取协议升级类型 */
function HttpClient:取协议升级类型()
    return self._hp:GetUpgradeType()
end
--/* 获取解析错误代码 */
function HttpClient:取解析错误码()
    return self._hp:GetParseErrorCode()
end
--/* 获取 HTTP 状态码 */
function HttpClient:取状态码()
    return self._hp:GetStatusCode()
end
--/* 获取某个请求头（单值） */
function HttpClient:取报头(lpszName)
    --GetHeaders
    return self._hp:GetHeader(lpszName)
end
--/* 获取所有请求头 */
function HttpClient:取所有报头()
    return self._hp:GetAllHeaders()
end
--/* 获取所有请求头名称 */
function HttpClient:取所有报头名称()
    return self._hp:GetAllHeaderNames()
end
--/* 获取 Cookie */
function HttpClient:取Cookie(lpszName)
    return self._hp:GetCookie(lpszName)
end
--/* 获取所有 Cookie */
function HttpClient:取所有Cookie()
    return self._hp:GetAllCookies()
end
--/* 获取当前 WebSocket 消息状态，传入 nullptr 则不获取相应字段 */
--GetWSMessageState
--/* 设置 HTTP 启动方式（默认：TRUE，自动启动） */
function HttpClient:置自动启动()
    self._hp:SetHttpAutoStart()
end
--/* 获取 HTTP 启动方式 */
function HttpClient:是否自动启动()
    return self._hp:IsHttpAutoStart()
end
return HttpClient
