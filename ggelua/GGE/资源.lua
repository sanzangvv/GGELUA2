-- @Author       : GGELUA
-- @Date         : 2021-10-30 13:05:32
-- @Last Modified by: baidwwy
-- @Last Modified time: 2022-01-05 05:07:45

local GGE资源包 = class('GGE资源包')

function GGE资源包:初始化(file, psd)
    self.file = file
    local db = require('lib.sqlite3')(file, psd)
    if db then
        local r = db:取值("select count(*) from sqlite_master where name='file';")
        if r == 0 then
            db:执行 [[
                CREATE TABLE "main"."file" (
                    "path"  TEXT,
                    "md5"  TEXT,
                    PRIMARY KEY ("path")
                );

                CREATE UNIQUE INDEX "main"."spath"
                ON "file" ("path" ASC);

                CREATE TABLE "main"."data" (
                    "type"  INTEGER DEFAULT 0,
                    "md5"  TEXT,
                    "time"  INTEGER,
                    "size"  INTEGER,
                    "dsize"  INTEGER,
                    "data"  BLOB,
                    PRIMARY KEY ("md5")
                );

                CREATE UNIQUE INDEX "main"."smd5"
                ON "data" ("md5" ASC);
            ]]
        end
        self._db = db
    else
        error('资源包打开失败。')
    end
end

function GGE资源包:是否存在(path)
    return self._db:取行数("select count(*) from file where path = '%s'; ", path) ~= 0
end

function GGE资源包:取数据(path)
    local t = self._db:查询一行("SELECT data FROM data WHERE md5 = (SELECT md5 FROM file WHERE path = '%s');", path)
    return t and t.data
end

function GGE资源包:写数据(path, data)
end

--======================================================================================================
local _ENV = require('SDL')

local GGE资源 = class 'GGE资源'

function GGE资源:初始化()
    self._res = {''}
end

function GGE资源:添加资源包(file, psd, idx)
    if type(file) == 'string' then
        local s, pack = pcall(GGE资源包, file, psd)
        if not s then
            error(file)
        end
        table.insert(self._res, idx or #self._res+1, pack)
    end
    return self
end

function GGE资源:删除资源包(file)
    for i, v in ipairs(self._res) do
        if v.file == file then
            table.remove(self._res, i)
            return true
        end
    end
end

function GGE资源:添加路径(path, idx)
    if type(path) == 'string' then
        table.insert(self._res, idx or #self._res+1, path)
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
    if select('#', ...) > 0 then
        path = path:format(...)
    end
    for i, v in ipairs(self._res) do
        if type(v) == 'string' then
            local path = v ~= '' and v .. '/' .. path or path
            local file = SDL.RWFromFile(path, 'rb')
            if file then
                file:RWclose()
                return path
            end
        elseif v:是否存在(path) then
            return v, v.file
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
    if select('#', ...) > 0 then
        path = path:format(...)
    end
    local r = self:是否存在(path)
    if r then
        if type(r) == 'string' then
            return SDL.LoadFile(r)
        end
        return r:取数据(path) --pack
    end
    return nil
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
