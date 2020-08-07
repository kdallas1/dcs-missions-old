dofile(baseDir .. "KD/Test/TestSpawn.lua")
dofile(baseDir .. "KD/Test/TestObject.lua")

testTrace = {
  _traceOn = true,
  _traceLevel = 3,
  _assert = true
}

local testError = false
local passCount = 0
local failCount = 0

function Test()
  env.info("Test: Running")
  
  RunTests {
    "*",
    Test_Object,
    Test_Spawn
  }

  env.info(string.format("Test: Finished (pass=%i fail=%i)", passCount, failCount))
  
  if (failCount > 0) then
    env.error("Unit tests failed: " .. failCount, true)
    return false
  end
  
  return true
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
        failCount = failCount + 1 
      else
        env.info("Test: [" ..suite .. "] Passed")
        passCount = passCount + 1
      end
      
    else
      env.error("Test: [" ..suite .. "] Invalid test " .. position, true)
    end
  end
end

function TestAssert(condition, errorString)
  if not condition then
    
    local lineNum = debug.getinfo(2, "S").linedefined
    local fileName = debug.getinfo(2, "S").source:match("^.+[\\\/](.+)\"?.?$")
    if not fileName then fileName = "Unknown" end

    funcName = (funcName and funcName or "?")
    env.info("Test: [" .. fileName .. "@" .. lineNum .. "] Error: " .. errorString)
    
    testError = true
    
  end
end
