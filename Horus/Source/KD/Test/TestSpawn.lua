local function Test_Foo()
  return true
end

local function Test_Bar()
  return true
end

function Test_Spawn()
  return RunTests {
    Test_Foo,
    Test_Bar,
  }
end
