-- @Author: baidwwy
-- @Date:   2021-08-14 11:47:41
-- @Last Modified by: baidwwy
-- @Last Modified time: 2021-12-08 12:09:28
--https://github.com/neoxic/lua-mongo/tree/master/doc

local MG集合 = class('MG集合')

function MG集合:MG集合(cli, col)
    self._cli = cli
    self._col = col
end

function MG集合:统计(query, options, prefs)
    return self._col:count(query or {}, options, prefs)
end

function MG集合:清空(opt)
    return self._col:drop(opt)
end

function MG集合:查询(query, options, prefs)
    local t = {}
    for v in self._col:find(query, options, prefs):iterator() do
        table.insert(t, v)
    end
    return t
end

function MG集合:遍历(query, options, prefs)
    return self._col:find(query, options, prefs):iterator()
end

function MG集合:查询一条(query, options, prefs)
    local r = self._col:findOne(query, options, prefs)
    return r and r:value()
end

function MG集合:查询修改(query, options)
    return self._col:findAndModify(query, options)
end

function MG集合:插入(document, flag_opt)
    if type(flag_opt) == 'number' then
        return self._col:insert(document, flag_opt)
    end
    return self._col:insertOne(document, flag_opt)
end
--TODO insertMany

function MG集合:删除(query, flags)
    return self._col:remove(query, flags)
end

function MG集合:删除全部(query, options)
    return self._col:removeMany(query, options)
end

function MG集合:删除一条(query, options)
    return self._col:removeOne(query, options)
end

function MG集合:重命名(dbname, collname, force, options)
    return self._col:rename(dbname, collname, force, options)
end

function MG集合:替换(query, document, options)
    return self._col:replaceOne(query, document, options)
end
--总是返回true
function MG集合:更新(query, document, flags)
    return self._col:update(query, document, flags)
end

function MG集合:更新全部(query, document, options)
    return self._col:updateMany(query, document, options)
end

function MG集合:更新一条(query, document, options)
    return self._col:updateOne(query, document, options)
end

function MG集合:取名称(query, options)
    return self._col:getName()
end

--TODO aggregate
--TODO createBulkOperation
--TODO findAndModify
--TODO getReadPrefs
--TODO setReadPrefs
local MG数据库 = class('MG数据库')

function MG数据库:MG数据库(cli, db)
    self._cli = cli
    self._db = db
end
--addUser
function MG数据库:创建集合(name, opt)
    return MG集合(self._cli, assert(self._db:createCollection(name, opt)))
end

function MG数据库:清空(opt)
    return assert(self._db:drop(opt))
end

function MG数据库:取集合(name)
    return MG集合(self._cli, assert(self._db:getCollection(name)))
end

function MG数据库:取集合列表(opt)
    return assert(self._db:getCollectionNames(opt))
end

function MG数据库:取名称()
    return self._db:getName()
end
--TODO getReadPrefs
function MG数据库:检查集合(name)
    return self._db:hasCollection(name)
end
--removeAllUsers
--removeUser
--setReadPrefs
local mongodb = require('mongo')

local MONGO = class('MongoDB')

MONGO.Binary = mongodb.Binary
MONGO.BSON = mongodb.BSON
MONGO.DateTime = mongodb.DateTime
MONGO.Decimal128 = mongodb.Decimal128
MONGO.Double = mongodb.Double
MONGO.Int32 = mongodb.Int32
MONGO.Int64 = mongodb.Int64
MONGO.Javascript = mongodb.Javascript
MONGO.ObjectID = mongodb.ObjectID
MONGO.ReadPrefs = mongodb.ReadPrefs
MONGO.Regex = mongodb.Regex
MONGO.Timestamp = mongodb.Timestamp

function MONGO:初始化(host, port, user, password)
    local uri = host
    if user then
        uri = string.format('mongodb://%s:%s@%s:%s', user, password, host, port)
    elseif port then
        uri = string.format('mongodb://%s:%s', host, port)
    end
    self._clt = assert(mongodb.Client(uri))
end

function MONGO:命令(dbname, command, options, prefs)
    return self._clt:command(dbname, command, options, prefs)
end

function MONGO:取集合(dbname, colname)
    local col = assert(self._clt:getCollection(dbname, colname))
    return MG集合(self, col)
end

function MONGO:取数据库(dbname)
    local db = assert(self._clt:getDatabase(dbname))
    return MG数据库(self, db)
end

function MONGO:取数据库列表(options)
    return assert(self._clt:getDatabaseNames(options))
end

function MONGO:取默认数据库()
    return assert(self._clt:getDefaultDatabase())
end

--TODO: getGridFS
--TODO: getReadPrefs
--TODO: setReadPrefs
return MONGO
