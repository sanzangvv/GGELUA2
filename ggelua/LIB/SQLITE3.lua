-- @Author: baidwwy
-- @Date:   2021-08-18 13:24:54
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 12:09:36
--http://lua.sqlite.org/

local sqlite3 = require('lsqlite3')
--print(sqlite3.version(),sqlite3.lversion())
local SQLITE3 = class('SQLITE3')

function SQLITE3:初始化(file, psd, flag)
    local db, code, err = sqlite3.open(file, flag)
    self._db = assert(db, err)
    if psd then
        local psd = string.format("PRAGMA key = '%s';", psd)
        self._db:exec(psd)
    end
    assert(self._db:exec('select count(*) from sqlite_master') == 0, '密码或文件错误') --self._db:errmsg()
    collectgarbage() --防止密码保存在内存
end

function SQLITE3:取对象()
    return self._db
end

function SQLITE3:检查语句(sql, ...)
    if select('#', ...) > 0 then
        sql = sql:format(...)
    end
    return sqlite3.complete(sql)
end

function SQLITE3:备份(db)
    local bu = sqlite3.backup_init(db:取对象(), 'main', self._db, 'main')
    if bu then
        bu:step(-1)
        bu:finish()
    end
end

function SQLITE3:执行(sql, ...)
    if select('#', ...) > 0 then
        sql = sql:format(...)
    end

    if self._db:exec(sql) == sqlite3.OK then
        return self._db:changes()
    else
        return false, self._db:errmsg()
    end
end

function SQLITE3:查询(sql, ...)
    if select('#', ...) > 0 then
        sql = sql:format(...)
    end
    local r = {}
    local n = 1
    for t in self._db:nrows(sql) do
        r[n] = t
        n = n + 1
    end
    return r
end

function SQLITE3:查询一行(sql, ...)
    if select('#', ...) > 0 then
        sql = sql:format(...)
    end
    local fun, vm = self._db:nrows(sql)
    return fun(vm)
end

function SQLITE3:遍历(sql, ...)
    if select('#', ...) > 0 then
        sql = sql:format(...)
    end
    return self._db:nrows(sql)
end
--select count(*) from 表
function SQLITE3:取值(sql, ...)
    if select('#', ...) > 0 then
        sql = sql:format(...)
    end
    local vm = self._db:prepare(sql)
    if vm and vm:step() == sqlite3.ROW then
        return vm:get_value(0)
    end
    return 0
end
--update 角色 set 数据=? where id=1
function SQLITE3:blob(sql, ...)
    if select('#', ...) > 0 then
        sql = sql:format(...)
    end
    local _, n = sql:gsub('?', '?')

    local vm = self._db:prepare(sql)

    if vm then
        if n > 0 then
            for i = 1, n do
                vm:bind_blob(i, select(i - 1 - n, ...))
            end
        end
        if vm:step() == sqlite3.DONE then
            return self._db:changes()
        end
    end
    return 0
end
--自动递增
function SQLITE3:取递增ID()
    return self._db:last_insert_rowid()
end

function SQLITE3:修改密码(v)
    return self._db:exec(string.format("PRAGMA rekey = '%s';", v)) == sqlite3.OK, self._db:errmsg()
end

function SQLITE3:开始事务()
    return self._db:exec('BEGIN') == sqlite3.OK, self._db:errmsg()
end

function SQLITE3:提交事务()
    return self._db:exec('COMMIT') == sqlite3.OK, self._db:errmsg()
end

function SQLITE3:回滚事务()
    return self._db:exec('ROLLBACK') == sqlite3.OK, self._db:errmsg()
end

function SQLITE3:清理()
    return self._db:exec('VACUUM') == sqlite3.OK, self._db:errmsg()
end

return SQLITE3
