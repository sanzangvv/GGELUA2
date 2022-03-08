-- @Author       : GGELUA
-- @Date         : 2021-09-19 06:42:20
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-08 09:17:48

local _ENV = require('SDL')

local SDL读写 = class 'SDL读写'

function SDL读写:SDL读写(file, mode)
    local tp = ggetype(file)
    if tp == 'string' then
        if type(mode) == 'number' and #file == mode then
            self._str = file
            self._rw = RWFromStr(file, mode)
        else
            self._rw = RWFromFile(file, mode)
        end
    elseif tp == 'userdata' and type(mode) == 'number' then
        self._rw = RWFromMem(file, mode)
    elseif tp == 'SDL_Memory' then --SDL.malloc
        self._rw = file:getrwops()
    end
    if not self._rw then
        error('打开失败->' .. file)
    end
end

function SDL读写:关闭()
    self._rw:RWclose()
end

function SDL读写:取对象()
    return self._rw
end

function SDL读写:取纹理(...)
    return require('SDL.纹理')(self._rw, ...)
end

function SDL读写:取精灵(...)
    return require('SDL.精灵')(self:取纹理(), ...)
end

function SDL读写:取图像(...)
    return require('SDL.图像')(self._rw, ...)
end

function SDL读写:取动画(...)
    return require('SDL.动画')(self._rw, ...)
end

function SDL读写:取文字(...)
    return require('SDL.文字')(self, ...)
end

function SDL读写:取音乐(...)
    return require('SDL.音乐')(self, ...)
end

function SDL读写:取音效(...)
    return require('SDL.音效')(self._rw, ...)
end
-- #define SDL_RWOPS_UNKNOWN   0U  /**< Unknown stream type */
-- #define SDL_RWOPS_WINFILE   1U  /**< Win32 file */
-- #define SDL_RWOPS_STDFILE   2U  /**< Stdio file */
-- #define SDL_RWOPS_JNIFILE   3U  /**< Android asset */
-- #define SDL_RWOPS_MEMORY    4U  /**< Memory stream */
-- #define SDL_RWOPS_MEMORY_RO 5U  /**< Read-Only memory stream */
function SDL读写:取类型()
    return self._rw:RWtype()
end

function SDL读写:取大小()
    return self._rw:RWsize()
end
RW_SEEK_SET = 0 --从头
RW_SEEK_CUR = 1 --当前
RW_SEEK_END = 2 --从尾

function SDL读写:置位置(offset, whence)
    return self._rw:RWseek(offset, whence or 0)
end

function SDL读写:取位置()
    return self._rw:RWtell()
end

function SDL读写:读取(...)
    return self._rw:RWread(...)
end

function SDL读写:写入(str)
    return self._rw:RWwrite(str)
end

SDL读写.seek = SDL读写.置位置
SDL读写.tell = SDL读写.取位置
SDL读写.read = SDL读写.读取
SDL读写.write = SDL读写.写入

function SDL读写:读数值(bit, endian)
    if bit == 8 then
        return self._rw:ReadU8()
    elseif bit == 16 then
        return endian and self._rw:ReadBE16() or self._rw:ReadLE16()
    elseif bit == 32 then
        return endian and self._rw:ReadBE32() or self._rw:ReadLE32()
    elseif bit == 64 then
        return endian and self._rw:ReadBE64() or self._rw:ReadLE64()
    end
end

function SDL读写:写数值(data, bit, endian)
    if bit == 8 then
        return self._rw:WriteU8(data)
    elseif bit == 16 then
        return endian and self._rw:WriteBE16(data) or self._rw:WriteLE16(data)
    elseif bit == 32 then
        return endian and self._rw:WriteBE32(data) or self._rw:WriteLE32(data)
    elseif bit == 64 then
        return endian and self._rw:WriteBE64(data) or self._rw:WriteLE64(data)
    end
end

return SDL读写
