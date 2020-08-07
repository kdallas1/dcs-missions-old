--- 
-- @param #Object self
-- @param #list list
function shuffleList(list)
  assert(list, "List is nil")
  
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
end
