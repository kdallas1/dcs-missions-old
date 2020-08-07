dofile(baseDir .. "KD/Test/TestSpawn.lua")
dofile(baseDir .. "KD/Test/TestObject.lua")

testTrace = {
  _traceOn = true,
  _traceLevel = 3,
  _assert = true
}

function RunTests(tests)
  for i, test in pairs(tests) do
    if not test then
      env.error("Test: Error, invalid test name", true)
    end
    
    env.info("Test: Start #" .. i .. " of " .. #tests)
    test()
    env.info("Test: Passed")
  end
end

function TestAssert(condition, errorString)
  if not condition then error(errorString) end
end

function Test()
  env.info("Test: Running")  
  env.setErrorMessageBoxEnabled(true)
  
  RunTests {
    Test_Object,
    Test_Spawn
  }
  
  env.setErrorMessageBoxEnabled(false)
  env.info("Test: Finished")
end
