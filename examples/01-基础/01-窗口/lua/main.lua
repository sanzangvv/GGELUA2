-- @Author              : GGELUA
-- @Last Modified by    : baidwwy
-- @Date                : 2022-03-23 10:09:27
-- @Last Modified time  : 2022-03-23 10:55:22

local SDL = require('SDL')
引擎 =
    require 'SDL.窗口' {
    标题 = 'GGELUA_窗口',
    宽度 = 800,
    高度 = 600,
    帧率 = 60
}

function 引擎:初始化()
end

function 引擎:更新事件(dt, x, y)
end

function 引擎:渲染事件(dt, x, y)
    if self:渲染开始(0x70, 0x70, 0x70) then
        self:渲染结束()
    end
end

function 引擎:窗口事件(ev)
    if ev == SDL.WINDOWEVENT_CLOSE then
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
