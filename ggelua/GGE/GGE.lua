-- @Author       : GGELUA
-- @Date         : 2021-10-30 13:05:32
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-06 14:19:33

class = require('GGE.class')
warn('@on') --开启警告
collectgarbage('generational') --使用分代GC

local type = type
local unpack = table.unpack
local pcall = pcall
local xpcall = xpcall

local function _traceback(L, t)
    local i = 1
    repeat
        local r = debug.getinfo(L, i)

        if r and r.what ~= 'C' then -- and not r.source:match('%a:')
            table.insert(t, string.format('%s:%s: %s', r.short_src, r.currentline, r.name or r.namewhat or 'no'))
        -- local l = 1
        -- repeat
        --     local k,v = debug.getlocal(L,i,l)
        --     if k and k:sub(1,1)~='(' then
        --         if type(v)=='string' then
        --             if #v>64 then
        --                 table.insert(t, string.format('    [local] %s = %s...', k,v:sub(64)))
        --             else
        --                 table.insert(t, string.format('    [local] %s = "%s"', k,v))
        --             end
        --         else
        --             table.insert(t, string.format('    [local] %s = %s', k,v))
        --         end
        --     end
        --     l=l+1
        -- until not k

        -- local u = 1
        -- repeat
        --     local k,v = debug.getupvalue(r.func,u)
        --     if k and k~='_ENV' then
        --         table.insert(t, string.format('    [upvalue] %s = %s;', k,v))
        --     end
        --     u=u+1
        -- until not k
        end
        i = i + 1
    until not r
    return t
end

local function _errfun(err)
    local t
    if type(err) == 'table' then --协程
        t = err
    else
        t = {'[\x1b[41;30mERROR\x1b[0m]', err}
    end

    _traceback(coroutine.running(), t)
    err = table.concat(t, '\n')
    if gge.platform == 'Windows' then
        print(err)
    else
        local SDL = require('SDL')
        SDL.Log(SDL.GetError())
        SDL.Log(err)
        gge.messagebox(err)
    end

    if type(gge.onerror) == 'function' then
        gge.onerror(err)
    elseif gge.isdebug then
        os.exit(-1)
    end
end

function ggexpcall(fun, ...)
    local r = {xpcall(fun, _errfun, ...)}
    if r[1] ~= nil then
        return unpack(r, 2)
    end
    return nil, unpack(r, 2)
end

function ggepcall(fun, ...)
    local r = {pcall(fun, ...)}
    if r[1] then
        return unpack(r, 2)
    end
    warn(r[2])
    return nil
end

function ggetype(v)
    local t = type(v)
    if t == 'table' or (t == 'userdata' and getmetatable(v)) then
        return v.__name or t
    end
    return t
end

function ggeassert(condition, err, level)
    if condition then
        return condition
    else
        error(err, level + 1)
    end
end

coroutine.FALSE = {}
function coroutine.xpcall(fun, ...)
    local L
    if type(fun) == 'function' then
        L = coroutine.create(fun)
    else
        L = fun
    end
    local r = {coroutine.resume(L, ...)}
    if r[1] == false then
        local t = _traceback(L, type(r[2]) == 'table' and r[2] or {'[\x1b[41;30mcoroutine.xpcall\x1b[0m]', r[2]})
        for i, v in ipairs(t) do
            print(v)
        end
        if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
            error(r[2], 1)
        else
            error('')
        end
        return coroutine.FALSE
    end
    return unpack(r, 2)
end

function ggesethook(...)
end

if gge.getplatform() == 'Android' then
    print = function(...)
        local arg = {}
        for i = 1, select('#', ...) do
            arg[i] = tostring(select(i, ...))
        end
        --log是变长va_list所以要转换%
        gge.log(table.concat(arg, ' '):gsub('%%','%%%%'))
    end
    warn = function(...)
        local arg = {}
        for i = 1, select('#', ...) do
            arg[i] = tostring(select(i, ...))
        end
        gge.warn(table.concat(arg, ' '))
    end

    os.clock = gge.getticks
end

if gge.entry == 'main' then
    print('--------------------------------------------------------------------------------------------------------------------')

    print(string.format('GGE %s  %s  %s', gge.version, gge.getluaversion(), gge.getsdlversion()))
    print(string.format('平台:%s  调试:%s  控制台:%s', gge.getplatform(), gge.isdebug, gge.isconsole))
    print('--------------------------------------------------------------------------------------------------------------------')
-- print("引擎目录:"..gge.getrunpath())
-- print("项目目录:"..gge.getcurpath())
-- print('--------------------------------------------------------------------------------------------------------------------')
-- print('package.path',string.format('"%s"', package.path))
-- print('package.cpath',string.format('"%s"', package.cpath))
-- print('--------------------------------------------------------------------------------------------------------------------')
end
