Table = {}
List = {}
Boolean = {}
Debug = {}

--- 
-- @param #list list
function Table:Shuffle(table)
  KDObject:AssertType(table, "table")
  for i = #table, 2, -1 do
    local j = math.random(i)
    table[i], table[j] = table[j], table[i]
  end
end

--- 
-- @param #list list
function List:Shuffle(list)
  -- In Lua, lists are tables
  Table:Shuffle(list)
end

--- 
-- @param #boolean value
function Boolean:ToString(value)
  KDObject:AssertType(value, "boolean")
  if value then return "True" else return "False" end
end

--- 
-- @param #number stackPosition
function Debug:GetInfo(stackPosition)

  if (not stackPosition) then
    stackPosition = 0
  end

  local _debug = {}

  _debug.funcName = debug.getinfo(2 + stackPosition, "n").name
  _debug.lineNum = debug.getinfo(2 + stackPosition, "S").linedefined
  _debug.fileName = debug.getinfo(2 + stackPosition, "S").source:match("^.+[\\\\/](.+)\"?.?$")
  
  if not _debug.fileName then _debug.fileName = "Unknown" end
  if not _debug.funcName then _debug.funcName = "Unknown" end

  return _debug

end

function Table:Concat(t1, t2)
  if not t2 then
    return t1
  end
  for i = 1, #t2 do
      t1[#t1 + i] = t2[i]
  end
  return t1
end
