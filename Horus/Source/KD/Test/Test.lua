testOnly = nil

dofile(baseDir .. "KD/Test/TestSpawn.lua")
dofile(baseDir .. "KD/Test/TestObject.lua")
dofile(baseDir .. "KD/Test/TestEvents.lua")
dofile(baseDir .. "KD/Test/TestMission.lua")

testTrace = {
  _traceOn = true,
  _traceLevel = 3,
  _assert = true
}

local testErrors = {}
local testError = false
local passCount = 0
local failCount = 0

function Test()
  env.info("Test: Running")
  
  if testOnly then
    RunSingleTest(testOnly, "*", 1)
  else
    RunTests {
      "*",
      Test_Object,
      Test_Events,
      Test_Spawn,
      Test_Mission
    }
  end

  env.info(string.format("Test: Finished (pass=%i fail=%i)", passCount, failCount))
  
  if (failCount > 0) then
    for i = 1, #testErrors do
      env.info(testErrors[i])
    end
    env.error("Unit tests failed: " .. failCount, true)
    return false
  end
  
  return true
end

function RunSingleTest(test, suite, position)
  env.info("Test: [" ..suite .. "] Start " .. position)
  test()
  
  if testError then
    env.info("Test: [" ..suite .. "] Failed")
    failCount = failCount + 1
  else
    env.info("Test: [" ..suite .. "] Passed")
    passCount = passCount + 1
  end
end

function RunTests(tests)
  local suite = "?"
  
  for i, test in pairs(tests) do
    local position = "#" .. (i - 1) .. " of " .. (#tests - 1)
    
    if (type(test) == "string") then
      suite = test
    elseif (type(test) == "function") then
      RunSingleTest(test, suite, position)
    else
      env.error("Test: [" ..suite .. "] Invalid test " .. position, true)
    end
  end
end

function TestAssert(condition, errorString)

  -- TODO: consider making this thread safe
  testError = not condition
  
  if not condition then
    
    local lineNum = debug.getinfo(2, "S").linedefined
    local fileName = debug.getinfo(2, "S").source:match("^.+[\\\/](.+)\"?.?$")
    if not fileName then fileName = "Unknown" end

    local error = "Test: [" .. fileName .. "@" .. lineNum .. "] Error: " .. errorString
    
    env.info(error)
    env.info("Test: Debug " .. debug.traceback())
    
    testErrors[#testErrors + 1] = error 
    
  end
end
