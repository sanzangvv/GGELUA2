-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-11 23:01:12

local gge = require('ggelua')
local SDL = require('SDL')
local im = require 'gimgui'

require('IMGUI.按钮')
require('IMGUI.标签')
require('IMGUI.表格')
require('IMGUI.菜单')
require('IMGUI.窗口')
require('IMGUI.弹出')
require('IMGUI.列表')
require('IMGUI.区域')
require('IMGUI.输入')
require('IMGUI.树')
require('IMGUI.提示')
require('IMGUI.文本')
require('IMGUI.纹理')
local IM控件 = require 'IMGUI.控件'
local init --引用一下，不然会释放

local IMGUI = class('IMGUI',IM控件)

function IMGUI:初始化(file, size)
    if not init then
        local fontfile = file
        if gge.platform == 'Windows' then
            if type(file) == 'string' then
                local rw = SDL.RWFromFile(file)
                if not rw then
                    fontfile = os.getenv('SystemRoot') .. '/Fonts/' .. file
                end
            else
                fontfile = os.getenv('SystemRoot') .. '/Fonts/simsun.ttc'
            end
        end

        im.Init(引擎:取对象(), fontfile, size or 14)
        self._demo = {false}
        init =
            SDL.AddEventHook(
            function(ev)
                return im.Event(ev)
            end
        )
    end
end

function IMGUI:更新()
    im.NewFrame()
    if self._demo[1] then
        im.ShowDemoWindow(self._demo)
    end
    IM控件.更新(self)
    im.EndFrame()
end

function IMGUI:打开DEMO()
    self._demo = {true}
    return self
end

function IMGUI:显示()
    im.Render()
end

function IMGUI:添加文字()
end


return IMGUI
