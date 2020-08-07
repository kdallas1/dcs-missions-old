dofile(baseDir .. "KD/Test/TestSpawn.lua")
dofile(baseDir .. "KD/Test/TestObject.lua")

testTrace = {
  _traceOn = true,
  _traceLevel = 3,
  _assert = true
}

function Test()
  env.info("Test: Running")  
  env.setErrorMessageBoxEnabled(true)
  
  RunTests {
    "*",
    Test_Object,
    Test_Spawn
  }
  
  env.setErrorMessageBoxEnabled(false)
  env.info("Test: Finished")
end

function RunTests(tests)
  local suite = "?"
  
  for i, test in pairs(tests) do
    if (type(test) == "string") then
      suite = test
    elseif (type(test) == "function") then
    
      if not test then
        env.error("Test: [" ..suite .. "] Error, invalid test name", true)
      end
      
      env.info("Test: [" ..suite .. "] Start #" .. (i - 1) .. " of " .. (#tests - 1))
      test()
      env.info("Test: [" ..suite .. "] Passed")
      
    else
      env.error("Test: [" ..suite .. "] Invalid test entry", true)
    end
  end
end

function TestAssert(condition, errorString)
  if not condition then error(errorString) end
end
