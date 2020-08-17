env = {
  error = function(s) print(s) end,
  info = function(s) print(s) end
}

local function scriptPath()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

baseDir = scriptPath() .. "../../Source/"

assert(tostring(_VERSION) == "Lua 5.1", "Requires Lua 5.1, but was " .. _VERSION)

dofile(baseDir .. "KD/Test/Test.lua")
dofile(baseDir .. "../Horus/Source/Test/TestMission05.lua")

Test {
  Test_Mission05
}
