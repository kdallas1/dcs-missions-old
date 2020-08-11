dofile(baseDir .. "KD/StateMachine.lua")

---
-- @type TestState
-- @extends KD.State#State
local TestState = {
  TestState1 = 0,
  TestState2 = 1
}

local function Test_Change_OnceStateCalledTwice_EventFiresOnce()
  local sm = StateMachine:New()
  
  local calls = 0
  sm:AddOnce(TestState.TestState1, function() calls = calls + 1 end)
  
  local result1 = sm:Change(TestState.TestState1)
  local result2 = sm:Change(TestState.TestState1)
  
  TestAssert(calls == 1, "Expected TestState1 to fire once, but called " .. calls .. " time(s)")
  TestAssert(result1, "Expected `Change` to return true on 1st call")
  TestAssert(not result2, "Expected `Change` to return false on 2nd call")
end

local function Test_Change_OnceStateNotAdded_NoEventFired()
  local sm = StateMachine:New()
  
  local fired = false
  function StateMachine:FireEvent() fired = true end
  
  local result = sm:Change(TestState.TestState1)
  
  TestAssert(not fired, "Expected no events to be fired")
  TestAssert(not result, "Expected `Change` to return false")
end

testOnly = Test_Change_CalledTwice_EventFiresOnce

function Test_StateMachine()
  return RunTests {
    "StateMachine",
    Test_Change_OnceStateCalledTwice_EventFiresOnce,
    Test_Change_OnceStateNotAdded_NoEventFired
  }
end
