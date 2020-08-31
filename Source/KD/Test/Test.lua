testOnly = nil

dofile(baseDir .. "KD/Test/TestObject.lua")
dofile(baseDir .. "KD/Test/TestUtilities.lua")
dofile(baseDir .. "KD/Test/TestSpawn.lua")
dofile(baseDir .. "KD/Test/TestStateMachine.lua")
dofile(baseDir .. "KD/Test/TestMissionEvents.lua")
dofile(baseDir .. "KD/Test/TestMission.lua")
dofile(baseDir .. "KD/Test/TestMocks.lua")

local tests = {
  "KD",
  Test_Object,
  Test_Utilities,
  Test_Spawn,
  Test_StateMachine,
  Test_MissionEvents,
  Test_Mission,
  Test_Mocks
}

testTrace = {
  _traceOn = true,
  _traceLevel = 3,
  _assert = true
}

local allErrors = {}
local errorCount = 0
local passCount = 0
local failCount = 0
local suite = "?"

function Test(extraTests)
  env.info("Test: Running, " .. _VERSION)
  
  if testOnly then
    RunSingleTest(testOnly, "*", 1)
  else
    RunTests(List:Concat(tests, extraTests))
  end

  env.info(string.format("Test: Finished (pass=%i fail=%i)", passCount, failCount))
  
  if (failCount > 0) then
    env.info("Test: Error summary...")
    for i = 1, #allErrors do
      env.info(allErrors[i])
    end
    env.error("Unit tests failed: " .. failCount)
    return false, failCount
  end
  
  return true
end

function RunSingleTest(test, suite, position)
  env.info("Test: [" ..suite .. "] Start " .. position)
  test()
  
  if (errorCount > 0) then
    env.info("Test: [" ..suite .. "] Failed")
    failCount = failCount + 1
  else
    env.info("Test: [" ..suite .. "] Passed")
    passCount = passCount + 1
  end
  
  -- reset for next test
  errorCount = 0
end

function RunTests(tests)

  local lastSuite = suite
  suite = "?"
  
  for i, test in pairs(tests) do
    local position = "#" .. (i - 1) .. " of " .. (#tests - 1)
    
    if (type(test) == "string") then
      suite = test
    elseif (type(test) == "function") then
      RunSingleTest(test, suite, position)
    else
      env.error("Test: [" ..suite .. "] Invalid test " .. position)
    end
  end
  
  suite = lastSuite
  
end

local function testToString(value, toString)

  local string = nil

  if value == nil then
    string = "[nil]"
  else
  
    if toString then
    
      assert(type(toString) == "function", "Arg: `toString` must be a function.")  
      string = toString(value)
      
    elseif (type(value) == "boolean") then
    
      string = Boolean:ToString(value)
      
    end
  
  end
  
  assert(string ~= nil, "String cannot be nil.")
  return string
  
end

function TestAssertEqual(expected, actual, description, toString)
  
  local expectedString = testToString(expected, toString)
  local actualString = testToString(actual, toString)
  
  local errorString = "Expected " .. description .. " to be [" .. expectedString .. "] but was [" .. actualString .. "]"
  TestAssert(expected == actual, errorString, 2)
  
end

function TestAssert(condition, errorString, debugStackPosition)
  
  if debugStackPosition == nil then debugStackPosition = 1 end
  
  if not condition then
    
    local debugInfo = Debug:GetInfo(debugStackPosition)
    local lineNum = debugInfo.lineNum
    local fileName = debugInfo.fileName

    local error = "Test: [" ..suite .. "] {" .. fileName .. "@" .. lineNum .. "} Error: " .. errorString
    
    env.info(error)
    env.info("Test: Debug " .. debug.traceback())
    
    errorCount = errorCount + 1 
    allErrors[#allErrors + 1] = error 
    
  end
end
