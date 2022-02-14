-- @Author              : GGELUA
-- @Date                : 2022-01-25 22:14:50
-- @Last Modified by    : GGELUA
-- @Last Modified time  : 2022-02-13 15:06:20
require('build/base')
pcall(require, 'ggerun')
编译目录('ggelua')
编译目录('./lua')
写出脚本('./.ggelua/ggelua')
local lfs = require('lfs')
list = 判断文件('./.ggelua/assetslist.lua') and require('assetslist') or {}
if type(list) ~= 'table' then
    list = {}
end
if arg[1] == 'windows' then
    执行('%s/GGELUAc.exe %s', 引擎目录, 项目目录)
else
    --adb shell pm dump com.GGELUA.game | findstr "versionName"
    local r = 执行('adb shell pm list packages | findstr "com.GGELUA.game"')
    if not r then
        list = {}
        执行('adb install -t %s/build/android/ggelua.apk', 引擎目录)
    end
    执行('adb shell am force-stop com.GGELUA.game')
    执行('adb shell "run-as com.GGELUA.game mkdir -pv /data/data/com.GGELUA.game/files/assets"')

    local function pushfile(file)
        执行('adb push %s/%s /sdcard/GGELUA/%s', 项目目录, file, file)
        执行('adb shell run-as com.GGELUA.game mkdir -pv /data/data/com.GGELUA.game/files/' .. file:match('(.+)/'))
        执行('adb shell "run-as com.GGELUA.game cp -fv /sdcard/GGELUA/%s /data/data/com.GGELUA.game/files/%s"', file, file)
    end

    for path, rel in 遍历目录('./assets') do
        local t = lfs.attributes(path, 'modification')
        path = path:sub(#rel + 1)
        if not list[path] or list[path] ~= t then
            pushfile(path)
            list[path] = t
        end
    end

    do
        os.remove('./.ggelua/assetslist.lua')
        local f = io.open('./.ggelua/assetslist.lua', 'w')
        f:write('return {', '\n')
        for k, v in pairs(list) do
            f:write(string.format('    ["%s"] = %s,\n', k, v))
        end
        f:write('}')
        f:close()
    end

    执行('adb push %s/.ggelua/ggelua /sdcard/GGELUA/ggelua', 项目目录)
    执行('adb shell "run-as com.GGELUA.game cp -fv /sdcard/GGELUA/ggelua /data/data/com.GGELUA.game/files/ggelua"')
    执行('adb shell am start com.GGELUA.game/.GGEActivity')
    执行('adb logcat --clear')
    执行('adb logcat -s SDL -s SDL/APP')
end
