skipMoose = true
dofile(baseDir .. "Horus/Source/Mission05.lua")

local function Test_Test()
  TestAssert(false, "Test")
end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_Test
  }
end
