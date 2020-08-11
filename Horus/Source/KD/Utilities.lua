List = {}
Boolean = {}

--- 
-- @param #list list
function List:Shuffle(list)
  Object:AssertType(list, "list")
  
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
end

function Boolean:ToString(value)
  Object:AssertType(value, "boolean")
  if value then return "True" else return "False" end 
end