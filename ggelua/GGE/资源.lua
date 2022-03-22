-- @Author       : GGELUA
-- @Date         : 2021-10-30 13:05:32
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-11 05:19:51

local SDL = require('SDL')

local GGE资源 = class 'GGE资源'

function GGE资源:初始化()
    self._res = {''}
end

function GGE资源:添加加载器(t, idx)
    if type(t) == 'table' and type(t.是否存在) == 'function' and type(t.取数据) == 'function' then
        table.insert(self._res, idx or #self._res + 1, t)
        return true
    end
    return self
end

function GGE资源:删除加载器(file)
end

function GGE资源:添加路径(path, idx)
    if type(path) == 'string' then
        table.insert(self._res, idx or #self._res + 1, path)
    end
    return self
end

function GGE资源:删除路径(path)
    for i, v in ipairs(self._res) do
        if v == path then
            table.remove(self._res, i)
            return true
        end
    end
end

function GGE资源:是否存在(path, ...)
    if type(path) ~= 'string' then
        return
    end
    if select('#', ...) > 0 then
        path = path:format(...)
    end
    for i, v in ipairs(self._res) do
        if type(v) == 'string' then
            local npath = v ~= '' and v .. '/' .. path or path
            local file = SDL.RWFromFile(npath, 'rb')
            if file then
                file:RWclose()
                return npath
            end
        elseif v:是否存在(path) then
            return v
        end
    end
    -- --绝对路径 用io.open?
    -- local file = SDL.RWFromFile(path, 'rb')
    -- if file then
    --     file:RWclose()
    --     return path
    -- end
    return false
end

function GGE资源:取数据(path, ...)
    if type(path) ~= 'string' then
        return
    end

    if select('#', ...) > 0 then
        path = path:format(...)
    end

    local r = self:是否存在(path)
    if r then
        if type(r) == 'string' then
            return SDL.LoadFile(r)
        end
        return r:取数据(path) --加载器
    end
end

function GGE资源:取纹理(...)
    local data = self:取数据(...)
    if data then
        local rw = require('SDL.读写')(data, #data)
        return require('SDL.纹理')(rw)
    end
end

function GGE资源:取精灵(...)
    local tex = self:取纹理(...)
    if tex then
        return require('SDL.精灵')(tex)
    end
end

function GGE资源:取图像(...)
    local data = self:取数据(...)
    if data then
        local rw = require('SDL.读写')(data, #data)
        return require('SDL.图像')(rw)
    end
end

-- function GGE资源:取动画(file)
--     return require("SDL.纹理")(file)
-- end

function GGE资源:取音乐(...)
    local path = self:是否存在(...)
    if path then
        return require('SDL.音乐')(path)
    end
end

function GGE资源:取音效(...)
    local data = self:取数据(...)
    if data then
        local rw = require('SDL.读写')(data, #data)
        return require('SDL.音效')(rw)
    end
end

function GGE资源:取文字(...)
    local data = self:取数据(...)
    if data then
        local rw = require('SDL.读写')(data, #data)
        return require('SDL.文字')(rw)
    end
end

return GGE资源
