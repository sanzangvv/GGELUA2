-- @Author              : GGELUA
-- @Date                : 2021-12-02 20:09:56
-- @Last Modified time  : 2022-01-27 08:08:56

-- [./] 表示项目目录
local tt = os.clock()

print('编译文件')
编译目录('ggelua')
编译目录('./lua')
if arg[1] == 'windows' then
    print('复制文件')
    复制文件('SDL2.dll', './build/SDL2.dll')
    复制文件('SDL_image.dll', './build/SDL_image.dll')
    复制文件('SDL_mixer.dll', './build/SDL_mixer.dll')
    复制文件('SDL_ttf.dll', './build/SDL_ttf.dll')
    复制文件('lua54.dll', './build/lua54.dll')
    复制文件('ggelua.dll', './build/ggelua.dll')
    复制文件('lib/gsdl2.dll', './build/lib/gsdl2.dll')

    联接目录('./assets', './build/assets')
    写出Windows('./build/GGELUA.exe')
elseif arg[1] == 'android' then
    --由于assets不支持中文，资源名转换
    -- print('处理文件')
    -- for path,rel in 遍历目录('./data') do
    --     local hash = gge.hash(path:sub(#rel+6))
    --     print(string.format('assets/%08x', hash), path)
    --     复制文件(path, string.format('./assets/%08x', hash), false)
    -- end
    写出Android('mygame', '我的游戏', '.vscode/ico.png')
end
print('编译完成\n用时:' .. os.clock() - tt .. '秒')
