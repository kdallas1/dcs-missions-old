dofile(baseDir .. "KD/Test/TestSpawn.lua")
dofile(baseDir .. "KD/Test/TestObject.lua")

testTrace = {
  _traceOn = true,
  _traceLevel = 3,
  _assert = true
}

local testError = false

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
    position = "#" .. (i - 1) .. " of " .. (#tests - 1)
    
    if (type(test) == "string") then
      suite = test
    elseif (type(test) == "function") then
      
      env.info("Test: [" ..suite .. "] Start " .. position)
      test()
      
      if testError then
        env.info("Test: [" ..suite .. "] Failed")
      else
        env.info("Test: [" ..suite .. "] Passed")
      end
      
    else
      env.error("Test: [" ..suite .. "] Invalid test " .. position, true)
    end
  end
end

function TestAssert(condition, errorString)
  if not condition then 
    error(errorString)
    testError = true
  end
end
