env = {
  error = function(s) error(s) end,
  info = function(s) print(s) end
}

local function scriptPath()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

baseDir = scriptPath()

assert(tostring(_VERSION) == "Lua 5.1", "Requires Lua 5.1, but was " .. _VERSION)

dofile(baseDir .. "KD/Test/Test.lua")
Test()
