Table = {}
List = {}
Boolean = {}

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
