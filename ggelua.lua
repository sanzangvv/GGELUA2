-- @Author       : GGELUA
-- @Date         : 2021-09-17 08:26:43
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-06 14:23:10

require('ggelua') --preload dll
io.stdout:setvbuf('no', 0)

local entry = ...

local function 分割路径(path)
    local t, n = {}, 1
    for match in path:gmatch('([^;]+)') do
        t[n] = match
        n = n + 1
    end
    return t
end

local lpath, lpath_, cpath
if gge.platform == 'Windows' then
    --lua脚本搜索
    lpath = '!/ggelua/?.lua;!/ggelua/?/?.lua;ggelua/?.lua;ggelua/?/?.lua;?.lua;lua/?.lua;lua/?/?.lua'
    lpath = lpath:gsub('!', gge.getrunpath())
    lpath_ = 分割路径(lpath)
    --lua模块搜索
    cpath = '?.dll;lib/?.dll;!/?.dll;!/lib/?.dll'
    cpath = cpath:gsub('!', gge.getrunpath())
elseif gge.platform == 'Android' then
    lpath = 'ggelua/?.lua;ggelua/?/?.lua;?.lua;lua/?.lua;lua/?/?.lua'
    lpath_ = 分割路径(lpath)
    cpath = gge.arg[1] .. '/lib?.so'
end

package.path = nil
package.cpath = nil
setmetatable(
    package,
    {
        __newindex = function(t, k, v)
            if v and k == 'path' then
                lpath = v:lower():gsub('\\', '/')
                lpath_ = 分割路径(lpath)
            elseif k == 'cpath' then
                cpath = v
            else
                rawset(t, k, v)
            end
        end,
        __index = function(t, k)
            if k == 'path' then
                return lpath
            elseif k == 'cpath' then
                return cpath
            end
        end
    }
)

-- if gge.platform=='Android' then
--     error("找不到脚本")
--     return
-- end

local function 处理路径(path)
    --相对路径
    -- local t = {}
    -- for match in path:gmatch("([^/]+)") do
    --     if match=='..' then
    --         table.remove(t)
    --     elseif match~='.' then
    --         table.insert(t, match)
    --     end
    -- end
    -- path = table.concat(t, "/")

    path = path:lower()
    path = path:gsub('%.', '/')
    path = path:gsub('\\', '/')
    return path
end

local 读取文件, 是否存在
if gge.isdebug then
    function 是否存在(path)
        local file = io.open(path, 'rb')
        if file then
            file:close()
            return true
        end
    end

    function 读取文件(path)
        local file = io.open(path, 'rb')
        if file then
            local data = file:read('a')
            file:close()
            return data
        end
    end

    function gge.dirscript(path, ...)
        if select('#', ...) > 0 then
            path = path:format(...)
        end
        local lfs = require('lfs')
        local dir, u = lfs.dir(path)
        local pt = {}
        return function()
            repeat
                local file = dir(u)
                if file then
                    local f = path .. '/' .. file
                    local attr = lfs.attributes(f)
                    if attr and attr.mode == 'directory' then
                        if file ~= '.' and file ~= '..' then
                            table.insert(pt, f)
                        end
                        file = '.'
                    else
                        return f
                    end
                elseif pt[1] then
                    path = table.remove(pt, 1)
                    dir, u = lfs.dir(path)
                    file = '.'
                end
            until file ~= '.'
        end
    end
else
    local script = gge.script
    gge.script = nil
    local list = {}
    for _, v in ipairs(script.getlist()) do
        list[v] = true
    end
    function 是否存在(file)
        return list[file]
    end

    function 读取文件(file)
        return script.getdata(file)
    end

    function gge.dirscript(path, ...)
        if select('#', ...) > 0 then
            path = path:format(...)
        end
        local k
        return function()
            repeat
                k = next(list, k)
                if k and k:find(path) then
                    return k
                end
            until not k
        end
    end
end

local function 搜索路径(path)
    for _, v in ipairs(lpath_) do
        local file = v:gsub('?', path)
        if 是否存在(file) then
            return file
        end
    end
end

local loaded = package.loaded
table.insert(
    package.searchers,
    2, --1是preload
    function(path)
        local npath = 处理路径(path)
        if loaded[npath] ~= nil then
            return function()
                return loaded[npath]
            end
        end
        local fpath = 搜索路径(npath)
        if fpath then
            return function()
                local data = 读取文件(fpath)
                local r, err = load(data, fpath)
                if err then
                    return error(err, 2)
                end
                local r = r()
                loaded[npath] = r == nil and true or r
                return loaded[npath]
            end
        end
    end
)

package.loaded =
    setmetatable(
    {},
    {
        __index = function(t, k)
            k = 处理路径(k)
            return loaded[k]
        end,
        __newindex = function(t, k, v)
            k = 处理路径(k)
            loaded[k] = v
        end,
        __pairs = function()
            return next, loaded
        end
    }
)

function gge.require(path, env, ...)
    path = path:gsub('\\', '/'):lower()
    local data = 读取文件(path)
    if data then
        return assert(load(data, path, 'bt', env))(...)
    end
end

require('GGE')

ggexpcall(require, entry)
