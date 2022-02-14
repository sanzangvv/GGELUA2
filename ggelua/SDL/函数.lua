-- @Author       : GGELUA
-- @Date         : 2021-09-19 06:42:20
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-01-22 20:32:05

local SDL = require('SDL')
local _ENV = setmetatable({}, {__index = _G})

local _pinfo = {
    '使用电池',
    '没有电池',
    '充电中',
    '已充满'
}
function 取电源信息()
    local s, secs, pct = SDL.GetPowerInfo()
    return _pinfo[s], pct
end

local Platform = SDL.GetPlatform()

local _ver = {
    [30] = '11',
    [29] = '10',
    [28] = '9',
    [27] = '8.1',
    [26] = '8.0',
    [25] = '7.1',
    [24] = '7.0',
    [23] = '6.0',
    [22] = '5.1',
    [21] = '5.0',
    [20] = '4.4W',
    [19] = '4.4',
    [18] = '4.3',
    [17] = '4.2',
    [16] = '4.1',
    [15] = '4.0.3',
    [14] = '4.0',
    [13] = '3.2',
    [12] = '3.1',
    [11] = '3.0',
    [10] = '2.3.3'
}
function 取安卓版本()
    if Platform == 'Android' then
        return _ver[SDL.GetAndroidSDKVersion()]
    end
    return ''
end

function 是否安卓电视()
    if Platform == 'Android' then
        return SDL.IsAndroidTV()
    end
end

function 安卓触发返回()
    if Platform == 'Android' then
        return SDL.AndroidBackButton()
    end
end

function 取内部存储路径()
    if Platform == 'Android' then
        return SDL.AndroidGetInternalStoragePath()
    end
    return '.'
end

function 取外部存储路径()
    if Platform == 'Android' then
        if SDL.AndroidGetExternalStorageState() & 2 == 2 then
            return SDL.AndroidGetExternalStoragePath()
        end
    end
    return '.'
end

function 安卓申请权限(t)
    if Platform == 'Android' then
        return SDL.AndroidRequestPermission(t)
    end
end

function 复制assets(src, dst, cb)
    local sf = SDL.RWFromFile(src, 'rb')
    if not sf then
        print('assets文件不存在', src)
        return
    end
    if sf:RWtype() ~= 3 then --SDL_RWOPS_JNIFILE
        sf:__close()
        print('assets文件不存在', src)
        return
    end

    require('GGE.函数').创建目录(dst)

    local df = SDL.RWFromFile(dst, 'wb')
    if df then
        local dsize, ssize = 0
        if type(cb) == 'function' then --回调
            ssize = sf:RWsize()
        end
        local function copy()
            local oc = SDL.GetTicks() + 30
            repeat
                local data = sf:RWread(4096)
                df:RWwrite(data)
                dsize = dsize + #data
            until ((ssize and SDL.GetTicks() > oc) or dsize == ssize or #data ~= 4096)

            if ssize and cb(dsize / ssize) == false then
                ssize = nil --中断
            end
            if not ssize or dsize == ssize then --结束
                sf:__close()
                df:__close()
                return 0
            end
            return 1
        end
        if ssize then
            引擎:定时(1, copy) --异步
        else
            copy()
        end
        return true
    else
        print('复制失败', sf, df)
    end
end
return _ENV
