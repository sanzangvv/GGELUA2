-- @Author              : GGELUA
-- @Date                : 2022-03-07 18:52:00
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-03-28 02:15:31

local SDL = require('SDL')
local ggetype = ggetype
local MIX = SDL.MIX_Init()

local SDL音乐 = class('SDL音乐')

function SDL音乐:初始化(file)
    local tp = ggetype(file)
    if tp == 'string' then
        self._mus = MIX.LoadMUS(file)
    elseif tp == 'SDL读写' then
        self._rw = file
        self._mus = MIX.LoadMUS_RW(file:取对象())
    elseif tp == 'SDL_RWops' then
        self._rw = file
        self._mus = MIX.LoadMUS_RW(file)
    end

    if self._mus then
        SDL._mixs[self] = self._mus
    else
        warn(GetError())
    end
end

function SDL音乐:播放(loop)
    if self._mus then
        if type(loop) == 'number' then
            self._mus:PlayMusic(loop)
        else
            self._mus:PlayMusic(loop and -1 or 0)
        end
    end
    return self
end

function SDL音乐:停止()
    MIX.HaltMusic()
end

function SDL音乐:暂停()
    MIX.PauseMusic()
    return self
end

function SDL音乐:恢复()
    MIX.ResumeMusic()
    return self
end

function SDL音乐:重置()
    MIX.RewindMusic()
    return self
end

function SDL音乐:是否暂停()
    return MIX.PausedMusic()
end

function SDL音乐:是否播放()
    return MIX.PlayingMusic()
end

function SDL音乐:置音量(v)
    MIX.VolumeMusic(v)
    return self
end

function SDL音乐:取音量()
    return MIX.VolumeMusic(-1)
end

function SDL音乐:置位置(v)
    MIX.SetMusicPosition(v)
    return self
end

return SDL音乐
