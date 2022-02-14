--[[
    @Author       : baidwwy
    @Date         : 2020-09-24 04:00:35
    @LastEditTime : 2021-04-25 22:56:39
--]]
io.stdout:setvbuf('no',0)
require("GGE.GGE")
local gge = gge or package.loadlib("ggelua", "luaopen_ggelua")()
local lfs = require("lfs")
local MD5 = require("md5")
local outpath = arg[1]
local indir = arg[2]
local outfile = arg[3]
local password = arg[4]

if not indir and not outfile then
    print("当前目录:"..outpath)
    print("请输入打包目录:")
    indir = io.stdin:read()
    print("请输入输出文件:")
    outfile = io.stdin:read()
    print("请输入打包密码:")
    password = io.stdin:read()
end

local function 遍历目录(path,...)
    if select("#", ...)>0 then
        path = path:format(...)
    end
    local lfs = require("lfs")
    local dir,u = lfs.dir(path)
    local pt = {}
    return function ()
        repeat
            local file = dir(u)
            if file then
                local f = path..'/'..file
                local attr = lfs.attributes (f)
                if attr and attr.mode == "directory" then
                    if file ~= "." and file ~= ".." then
                        table.insert(pt, f)
                    end
                    file = "."
                else
                    return f
                end
            elseif pt[1] then
                path = table.remove(pt, 1)
                dir,u = lfs.dir(path)
                file = "."
            end
        until file ~= "."
    end
end

local function 读取文件(path)
    local file<close> = io.open(path, 'rb');
    if file then
        return file:read('a')
    end
end


local SQL = require("lib.sqlite3")(outfile,password)

if SQL:取行数("select count(*) from sqlite_master where name='file';")==0 then
    SQL:执行[[
        CREATE TABLE "main"."file" (
            "path"  TEXT,
            "md5"  TEXT,
            PRIMARY KEY ("path")
        );

        CREATE UNIQUE INDEX "main"."spath"
        ON "file" ("path" ASC);

        CREATE TABLE "main"."data" (
            "type"  INTEGER DEFAULT 0,
            "md5"  TEXT,
            "time"  INTEGER,
            "size"  INTEGER,
            "size2"  INTEGER,
            "data"  BLOB,
            PRIMARY KEY ("md5")
        );

        CREATE UNIQUE INDEX "main"."smd5"
        ON "data" ("md5" ASC);
    ]]
end


SQL:开始事务()
    for path in 遍历目录(indir) do
        local time = lfs.attributes(path,'modification')
        local spath = path:gsub(indir.."/","")
        
        local t = SQL:查询一行("SELECT time,md5 FROM data WHERE md5 = (SELECT md5 FROM file WHERE path = '%s');",spath)
        if not t or (t.time~=time) then
            local data = 读取文件(path)
            local md5 = MD5(data)
            if not t or t.md5 ~= md5 then
                if t then
                    SQL:执行("DELETE FROM file WHERE md5 = '%s'",t.md5)
                    SQL:执行("DELETE FROM data WHERE md5 = '%s'",t.md5)
                end
                
                SQL:执行("insert into file(path,md5) values('%s','%s')",
                    spath,
                    md5
                )
                
                SQL:执行("insert into data(md5,time,size) values('%s','%d','%d')",
                    md5,
                    time,
                    #data
                )
                
                SQL:UPBLOB("update data set data=? where md5='%s'",md5,data)
                print(time,md5,spath)
            end
        end
    end
SQL:提交事务()

print('打包完成')