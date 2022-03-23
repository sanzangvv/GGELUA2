-- @Author              : GGELUA
-- @Last Modified by    : baidwwy
-- @Date                : 2022-03-23 10:09:30
-- @Last Modified time  : 2022-03-23 11:24:09

local SDL = require('SDL')
引擎 =
    require 'SDL.窗口' {
    标题 = 'GGELUA_矩形',
    宽度 = 800,
    高度 = 600,
    帧率 = 60
}

function 引擎:初始化()
    ttf = require('SDL.文字')('../../../assets/simsun.ttc', 20)
    rect = require('SDL.矩形')(200, 50, 100, 100)
    rect2 = require('SDL.矩形')(200, 50, 50, 50)
end

function 引擎:更新事件(dt, x, y)
end

function 引擎:渲染事件(dt, x, y)
    if self:渲染开始(0x70, 0x70, 0x70) then
        rect:显示()
        rect2:显示(x, y)
        local c = '检查点:' .. tostring(rect:检查点(x, y))
        ttf:显示(10, 10, c)
        local c = '检查交集:' .. tostring(rect:检查交集(rect2))
        ttf:显示(10, 40, c)

        if rect:检查交集(rect2) then
            rect:取交集(rect2):显示(200, 200)
        end

        rect:取并集(rect2):显示(200, 300)
        self:渲染结束()
    end
end

function 引擎:窗口事件(消息)
    if 消息 == SDL.WINDOWEVENT_CLOSE then
        引擎:关闭()
    end
end

function 引擎:键盘事件(KEY, KMOD, 状态, 按住)
    if not 状态 then --弹起
        if KEY == SDL.KEY_F1 then
            print('F1')
        end
    end
    if KMOD & SDL.KMOD_LCTRL ~= 0 then
        print('左CTRL', 按住)
    end
    if KMOD & SDL.KMOD_ALT ~= 0 then
        print('左右ALT', 按住)
    end
end

function 引擎:鼠标事件()
end

function 引擎:输入事件()
end

function 引擎:销毁事件()
end
