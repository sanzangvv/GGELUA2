-- @Author       : GGELUA
-- @Date         : 2021-09-01 21:04:09
-- @Last Modified by    : baidwwy
-- @Last Modified time  : 2022-02-21 03:29:48

local im = require 'gimgui'
local IM控件 = require 'IMGUI.控件'

local IM表格 = class('IM表格', IM控件)

function IM表格:初始化(name)
    self._list = {}
    self._data = {}
    self._sel = {}
    self._flag = 1 | 2 | 32 | 64 | 1792 | 0x1000000 | 0x2000000
    --self._flag = self._flag&~128--ImGuiTableFlags_BordersInnerH
    --ImGuiTableFlags_Resizable|ImGuiTableFlags_RowBg|
    --ImGuiTableFlags_Borders|ImGuiTableFlags_ScrollX|ImGuiTableFlags_ScrollY
end

-- function IM表格:冻结(row, col)--固定行列 不被 滚动影响
--     im.TableSetupScrollFreeze(col or 0, row or 0)
--     return self
-- end

function IM表格:_更新(dt)
    if im.BeginTable(self.名称, #self._list, self._flag) then
        if not self._head then
            for i, v in ipairs(self._list) do
                im.TableSetupColumn(v)
            end
            im.TableHeadersRow()
        end
        for h, v in ipairs(self._data) do
            im.TableNextRow()
            self._sel[h].行号 = h
            self.当前行 = h
            for l, v in ipairs(v) do
                im.TableNextColumn() --im.TableSetColumnIndex(i)
                v:_更新(dt)
                if self._pop and l == 1 then
                    if self._pop:_更新(dt) then
                        self._sel[h]:选中事件()
                    end
                end
            end
        end
        im.EndTable()
    end
end

function IM表格:添加列(...)
    for i, v in ipairs({...}) do
        table.insert(self._list, tostring(v))
    end
    return self
end

function IM表格:添加(...)
    local arg = {...}
    local line = {}
    for i, _ in ipairs(self._list) do
        line[i] = IM控件()
        if arg[i] then
            if i == 1 then
                local sel = line[i]:创建选项(arg[i])

                function sel.选中事件()
                    for i, v in ipairs(self._sel) do
                        v:置选中(v == sel)
                    end
                    self.选中行 = sel.行号
                end

                function sel.双击事件()
                    self:发送消息('双击事件', sel.行号)
                end
                table.insert(self._sel, sel)
            else
                line[i]:创建文本(arg[i])
            end
        end
    end
    table.insert(self._data, line)
    return r
end

function IM表格:删除()
    --self._sel
    --self._data
end

function IM表格:清空()
    self._data = {}
    return self
end

function IM表格:取列数量()
    return #self._list
end

function IM表格:创建弹出()
    self._pop = require('IMGUI.弹出')()
    return self._pop
end
--==============================================================================
function IM控件:创建表格(name, ...)
    assert(self[name] == nil, name .. '->已经存在')
    self[name] = IM表格(name, ...)
    table.insert(self._子控件, self[name])
    return self[name]
end
return IM表格
