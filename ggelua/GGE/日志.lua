-- @Author       : GGELUA
-- @Date         : 2021-10-30 13:05:32
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-07 02:58:28

local cprint = require('cprint')
local _isdebug = require('ggelua').isdebug
local lcolor = {
    INFO = '\x1b[47;30mINFO\x1b[0m',
    WARN = '\x1b[43;30mWARN\x1b[0m',
    ERROR = '\x1b[41;30mERROR\x1b[0m'
}

local GGE日志 = class('GGE日志')

function GGE日志:GGE日志(file, logger)
    self.logger = logger or 'GGELUA'
    self.SQL = require('LIB.SQLITE3')(file or 'log.db3')

    local r = self.SQL:取值("select count(*) from sqlite_master where name='log';")
    if r == 0 then
        self.SQL:执行 [[
            CREATE TABLE "log" (
                "date" integer NOT NULL,
                "logger" TEXT,
                "level" integer NOT NULL,
                "message" TEXT NOT NULL,
                "exception" TEXT
              );
        ]]
    end
end

function GGE日志:LOG(level, msg, ...)
    if select('#', ...) > 0 then
        msg = msg:format(...)
    end
    local time = os.time()
    cprint(string.format('[%s] [%s] [%s] %s', os.date('%X', time), self.logger, lcolor[level] or level, tostring(msg)))
    local r =
        self.SQL:执行(
        "insert into log(date,logger,level,message) values('%d','%s','%s','%s')",
        time,
        self.logger,
        level,
        msg
    )
end

function GGE日志:INFO(msg, ...)
    self:LOG('INFO', msg, ...)
end

function GGE日志:WARN(msg, ...)
    self:LOG('WARN', msg, ...)
end

function GGE日志:ERROR(msg, ...)
    self:LOG('ERROR', msg, ...)
end

function GGE日志:DEBUG(msg, ...)
    if _isdebug then
        self:LOG('DEBUG', msg, ...)
    end
end
return GGE日志
