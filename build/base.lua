-- @Author       : GGELUA
-- @Date         : 2021-12-07 21:06:14
-- @Last Modified by    : GGELUA
-- @Last Modified time  : 2022-02-13 14:59:44

io.stdout:setvbuf('no', 0)
gge = package.loadlib('ggelua', 'luaopen_ggelua')()
local lfs = require('lfs')

引擎目录 = gge.getrunpath()
项目目录 = arg[2]
--gge.getcur1path()--项目目录

-- local function _处理路径(path) --处理sep和大小写
--     path = path:lower() --小写
--     path = path:gsub('\\', '/')
--     return path
-- end

引擎目录 = 引擎目录:gsub('\\', '/')
if 项目目录 then
    项目目录 = 项目目录:gsub('\\', '/')
end
print(引擎目录, 项目目录)
package.path = package.path .. ';.\\.vscode\\?.lua;.\\.ggelua\\?.lua'

--转换到绝对路径
local function 绝对路径(path, ...)
    if select('#', ...) > 0 then
        path = path:format(...)
    end
    path = path:gsub('\\', '/')

    if path:sub(2, 2) == ':' then
        if 项目目录 and path:find(项目目录) then
            return path, 项目目录 .. '/'
        elseif path:find(引擎目录) then
            return path, 引擎目录 .. '/'
        end
        warn('未知路径->' .. path)
        return path, ''
    end

    if path:sub(1, 2) == './' then --项目目录
        path = path:gsub('.', 项目目录, 1) --%.
        return path, 项目目录 .. '/'
    else
        path = 引擎目录 .. '/' .. path
    end
    return path, 引擎目录 .. '/'
end

local function 分割文本(str, mark)
    if str then
        local r = {}
        if mark == '%' then
            mark = '([^' .. mark .. '%]+)'
        else
            mark = '([^' .. mark .. ']+)'
        end

        for match in tostring(str):gmatch(mark) do
            if match ~= '' then
                table.insert(r, match)
            end
        end
        return r
    end
    return {}
end

function 创建目录(path)
    path = path:gsub('\\', '/'):match('(.+)/')
    path = 分割文本(path, '/')
    for i, v in ipairs(path) do
        lfs.mkdir(table.concat(path, '\\', 1, i))
    end
end

function 删除目录(path, all)
    path = 绝对路径(path):gsub('/', '\\')
    if all then
        os.execute('RMDIR /S /Q ' .. path)
    else
        os.execute('RMDIR /Q ' .. path)
    end
end

function 判断文件(path)
    local file = io.open(绝对路径(path), 'rb')
    if file then
        file:close()
        return true
    end
    return false
end

function 读取文件(path)
    local file = io.open(绝对路径(path), 'rb')
    if file then
        local data = file:read('a')
        file:close()
        return data
    end
end

function 写出文件(path, data)
    local file = io.open(绝对路径(path), 'wb')
    if file then
        file:write(data)
        file:close()
        return true
    else
        print('写出失败', path)
    end
    return false
end

function 复制文件(old, new, Y)
    if 判断文件(new) and Y == false then
        return
    end

    old, new = 绝对路径(old), 绝对路径(new)
    创建目录(new)

    local rf = io.open(old, 'rb')
    if rf then
        local wf = io.open(new, 'wb')
        if wf then
            wf:write(rf:read('a'))
            rf:close()
            wf:close()
            return true
        end
        rf:close()
    end
    return false
end

function 遍历目录(path)
    local path, rel = 绝对路径(path)

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
                    return f, rel
                end
            elseif pt[1] then
                path = table.remove(pt, 1)
                dir, u = lfs.dir(path)
                file = '.'
            end
        until file ~= '.'
    end
end

--lfs.link(a,b,true)需要管理权限
function 联接目录(a, b)
    a, b = 绝对路径(a), 绝对路径(b)
    创建目录(b:match('(.+)/'))
    a, b = a:gsub('/', '\\'), b:gsub('/', '\\')
    os.execute(string.format('mklink /j "%s" "%s"', b, a))
end

function 联接文件(a, b)
    a, b = 绝对路径(a):gsub('/', '\\'), 绝对路径(b):gsub('/', '\\')
    创建目录(b)
    os.execute(string.format('mklink /h "%s" "%s"', b, a))
end
--把资源打包到sqlite
-- function 打包目录(path, file, psd)
--     path, file = 绝对路径(path), 绝对路径(file)
--     local env = setmetatable({arg = {arg[1], path, file, psd}}, {__index = _G})

--     loadfile(引擎目录 .. '/tools/torespack.lua', 'bt', env)()
-- end

--启动脚本
local script, core = {}
do
    local r = assert(读取文件(引擎目录 .. '/ggelua.lua'), '读取失败:ggelua.lua')
    local fun = assert(load(r, 'ggelua.lua'))
    core = string.dump(fun)
end

function 编译重置()
    script, core = {}
end

function 编译目录(path, strip)
    for path, rel in 遍历目录(path) do
        if path:sub(-3) == 'lua' then
            local r = assert(读取文件(path), '读取失败:' .. path)
            path = path:sub(#rel + 1):lower() --删除绝对路径
            local fun = assert(load(r, path))
            script[path] = string.dump(fun, strip)
            print('dump -> ' .. path)
        end
    end
end

function 编译文件(path, strip)
    local path, rel = 绝对路径(path)
    if path:sub(-3) == 'lua' then
        local r = assert(读取文件(path), '读取失败:' .. path)
        path = path:sub(#rel + 1):lower() --删除绝对路径
        local fun = assert(load(r, path))
        script[path] = string.dump(fun, strip)
        print('dump -> ' .. path)
    end
end

local function getscript()
    local data, path = {}, {}
    for k, v in pairs(script) do
        table.insert(path, k)
        table.insert(data, v)
    end
    local head = 'GGEP' .. string.pack('<I4I4', #path, 0)
    local list, offset = {}, 12 + #path * string.packsize('<c256I4I4I4')
    for i, v in ipairs(path) do
        table.insert(list, string.pack('<c256I4I4I4', v, gge.hash(v), offset, #data[i]))
        offset = offset + #data[i]
    end
    data = head .. table.concat(list) .. table.concat(data)
    return data
end

function 写出脚本(path)
    创建目录(path)
    local file = path
    if type(path) == 'string' then
        file = io.open(绝对路径(path), 'wb')
    end
    if file then
        local data = getscript()
        file:write(core)
        file:write(data)
        file:write(string.pack('<I4I4I4', 0x20454747, #core, #data))
        file:close()
        return true
    end
end

function 写出Windows(path, c)
    复制文件(c and 'GGELUAc.exe' or 'GGELUA.exe', path)
    path = 绝对路径(path)
    创建目录(path)

    local file = io.open(path, 'r+b')

    if file then
        if file:seek('end', -12) then
            local glue = file:read(12)
            if glue and #glue == 12 then
                local sig, s1, s2 = string.unpack('<I4I4I4', glue)
                if sig == 0x20454747 then
                    file:seek('end', -(12 + s1 + s2))
                end
                file:seek('cur') --没有这句，会有奇怪的数据
                写出脚本(file)
                return true
            end
        end
    end
    error('写出失败', 2)
    return false
end

function 执行(file, ...)
    if select('#', ...) > 0 then
        file = file:format(...)
    end
    print(file)
    local p = io.popen(file, 'r')
    local ret = {}
    repeat
        local r = p:read('*l')
        if r then
            print(r)
            table.insert(ret, r)
        end
    until not r

    p:close()
    ret = table.concat(ret, '\n')
    return ret ~= '' and ret
end

local function android_icon(file)
    local SDL = require('gsdl2')
    require('gsdl2.image')
    SDL.IMG_Init()
    if 判断文件(file) then
        local src = SDL.IMG_LoadARGB8888(file)
        if src then
            local name = {
                --32 ldpi
                [48] = 'mipmap-mdpi-v4',
                [72] = 'mipmap-hdpi-v4',
                [96] = 'mipmap-xhdpi-v4',
                [144] = 'mipmap-xxhdpi-v4',
                [192] = 'mipmap-xxxhdpi-v4'
            }
            local function stretch(w, h)
                local dst = SDL.CreateRGBSurfaceWithFormat(w, h)
                src:SoftStretchLinear(nil, dst, nil)
                dst:SavePNG(string.format('.ggelua/android/res/%s/ic_launcher.png', name[w]))
                print(string.format('./.ggelua/android/res/%s/ic_launcher.png', name[w]))
            end
            stretch(192, 192)
            stretch(144, 144)
            stretch(96, 96)
            stretch(72, 72)
            stretch(48, 48)
        end
    else
        print('文件不存在', file)
    end
end

function 写出Android(pack, name, ico, key)
    if pack:match('[a-zA-Z]+') ~= pack then
        print('\x1b[31m包名必须是英文\x1b[0m', pack)
        return
    end
    local base = 绝对路径('build/android')
    local java = base .. '/OpenJDK/bin/java.exe'
    local align = base .. '/zipalign.exe'
    local apktool = base .. '/apktool.jar'
    local apksigner = base .. '/apksigner.jar'
    local inapk = base .. '/GGELUA.apk'
    local output = './.ggelua/android'
    local outapk = name .. '.apk'
    local keystore = base .. '/debug.keystore'

    删除目录(output .. '/assets/assets') --先删除,否则 apktool会删除所有子文件
    print('开始解包', inapk)
    执行(string.format('%s -jar %s decode %s --force-all -output %s', java, apktool, inapk, output))
    删除目录(output .. '/assets/assets', true)
    联接目录('./assets', output .. '/assets/assets')

    print('写出脚本')
    写出脚本(output .. '/assets/ggelua')

    if pack then
        print('修改包名', pack)
        写出文件(output .. '/AndroidManifest.xml', 读取文件(output .. '/AndroidManifest.xml'):gsub('com.GGELUA.game', 'com.GGELUA.' .. pack))
        创建目录(绝对路径('%s/smali/com/GGELUA/%s/', output, pack))
        for path, rel in 遍历目录(output .. '/smali/com/GGELUA/game') do
            local data = 读取文件(path)
            data = data:gsub('com%.GGELUA%.game', 'com.GGELUA.' .. pack)
            data = data:gsub('com/GGELUA/game', 'com/GGELUA/' .. pack)
            path = path:gsub('com/GGELUA/game', 'com/GGELUA/' .. pack)
            写出文件(path, data)
            print(path)
        end
        删除目录(output .. '/smali/com/GGELUA/game', true)
    end

    if name then
        print('修改APP名称', name)
        写出文件(output .. '/res/values/strings.xml', 读取文件(output .. '/res/values/strings.xml'):gsub('GGELUA', name))
    end

    if ico then
        print('修改APP图标')
        android_icon(绝对路径(ico))
    end

    print('开始打包')
    执行(string.format('%s -jar %s build %s --force-all -output %s', java, apktool, output, 'outapk'))

    if key then
        keystore = key
    end
    print('签名', keystore)
    执行(string.format('%s -p -f -v 4 %s %s', align, 'outapk', 'align'))
    os.remove('outapk')

    执行(string.format('%s -jar %s sign -verbose --ks %s --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android --out %s align', java, apksigner, keystore, outapk))
    os.remove('align')
    执行(string.format('%s -jar %s verify -verbose %s', java, apksigner, outapk))
end

if not 项目目录 then
    编译目录('ggelua')
    编译目录('lua')
    写出脚本('../Projects/android-vs/app/GGELUA/app/src/main/assets/ggelua')
end
