-- @Author              : GGELUA
-- @Last Modified by    : baidwwy
-- @Date                : 2022-03-23 10:09:27
-- @Last Modified time  : 2022-03-23 10:53:47

local SDL = require('SDL')
引擎 =
    require 'SDL.窗口' {
    标题 = 'GGELUA_文字',
    宽度 = 800,
    高度 = 600,
    帧率 = 60
}
function 引擎:初始化()
    ttf = require('SDL.文字')('../../../assets/simsun.ttc', 14)

    测试 = ttf:取精灵('测试测试')

    描边精灵 = ttf:取描边精灵('描边精灵', 255, 0, 0)
    ttf:置颜色(0, 0, 0)
    投影精灵 = ttf:取投影精灵('投影精灵', 255, 255, 0, 150)

    --emoji = require('SDL.文字')(os.getenv('SystemRoot') .. '/Fonts/seguiemj.ttf', 16)
    --🐂🍺 = emoji:取精灵('🐂🍺') --win10
end

function 引擎:更新事件(dt, x, y)
end

function 引擎:渲染事件(dt, x, y)
    if self:渲染开始(0x70, 0x70, 0x70) then
        ttf:显示(10, 10, 引擎:取FPS())
        测试:显示(10, 30)
        描边精灵:显示(10, 50)
        投影精灵:显示(10, 70)
        --🐂🍺:显示(10, 100)
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
