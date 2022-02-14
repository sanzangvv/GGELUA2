--[[
    @Author       : GGELUA
    @Date         : 2021-02-10 17:12:37
    @LastEditTime : 2021-03-15 13:22:52
--]]
io.stdout:setvbuf('no',0)
local gge = package.loadlib("ggelua", "luaopen_ggelua")()
local base64 = require("base64")
local outpath = arg[1]
print("当前目录:"..outpath)
print("请输入转换的文件名:")
local infile = "/"..io.stdin:read()
local outfile = infile..".b64"
print(outpath..outfile)
function readfile(path)
    local file<close> = io.open(path, 'rb');
    if file then
        return file:read('a')
    end
end

function writefile(path,data)
    local file<close> = io.open(path,"wb")
    if file then
        file:write(data)
        return true
    end
    return false
end

function tobase64(data)
    data = base64.encode(data)
    local ret = "return [[\r\n"

    for i=1,#data,100 do
        ret = ret .. data:sub(i,i+99).."\r\n"
    end

    return ret.."]];"
end
print(writefile(outpath..outfile,
    tobase64(
        readfile(outpath..infile)
    )))

