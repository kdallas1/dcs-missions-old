dofile(baseDir .. "KD/StateMachine.lua")

---
-- @type TestState
-- @extends KD.State#State
local TestState = {
  TestState1 = 0,
  TestState2 = 1
}

local function Test_ActionOnce_ChangeCalledTwice_ActionFiresOnce()
  local sm = StateMachine:New()
  
  local calls = 0
  sm:ActionOnce(TestState.TestState1, function() calls = calls + 1 end)
  
  local result1 = sm:Change(TestState.TestState1)
  local result2 = sm:Change(TestState.TestState1)
  
  TestAssert(calls == 1, "Expected TestState1 to fire once, but called " .. calls .. " time(s)")
  TestAssert(result1, "Expected `Change` to return true on 1st call")
  TestAssert(not result2, "Expected `Change` to return false on 2nd call")
end

local function Test_Change_OnceStateNotAdded_NoEventFired()
  local sm = StateMachine:New()
  
  local fired = false
  function sm:FireEvent() fired = true end
  
  local result = sm:Change(TestState.TestState1)
  
  TestAssert(not fired, "Expected no events to be fired")
  TestAssert(not result, "Expected `Change` to return false")
end

local function Test_TriggerOnce_TriggerFalse_NoActionFired()
  local sm = StateMachine:New()
  
  local fired = false
  local trigger = false
  
  sm:TriggerOnce(
    TestState.TestState1,
    function() return trigger end,
    function() fired = true end
  )
  
  sm:CheckTriggers()
  
  TestAssert(not fired, "Expected no events to be fired")
end

local function Test_TriggerOnce_TriggeredOnCheckTriggers_ActionFiresOnce()
  local sm = StateMachine:New()
  
  local calls = 0
  local trigger = false
  
  sm:TriggerOnce(
    TestState.TestState1,
    function() return trigger end,
    function() calls = calls + 1 end
  )
  
  sm:CheckTriggers()
  trigger = true
  sm:CheckTriggers()
  sm:CheckTriggers()
  
  TestAssert(calls == 1, "Expected TestState1 to fire once, but called " .. calls .. " time(s)")
end

local function Test_TriggerOnceAfter_TriggerAfterEvent_ActionFiresOnce()
  local sm = StateMachine:New()
  
  local calls = 0
  
  sm:TriggerOnceAfter(
    TestState.TestState2,
    TestState.TestState1,
    function() return true end,
    function() calls = calls + 1 end
  )
  
  sm:CheckTriggers()
  sm:Change(TestState.TestState1)
  sm:CheckTriggers()
  sm:CheckTriggers()
  
  TestAssert(calls == 1, "Expected TestState1 to fire once, but called " .. calls .. " time(s)")
end

function Test_StateMachine()
  return RunTests {
    "StateMachine",
    Test_ActionOnce_ChangeCalledTwice_ActionFiresOnce,
    Test_Change_OnceStateNotAdded_NoEventFired,
    Test_TriggerOnce_TriggerFalse_NoActionFired,
    Test_TriggerOnce_TriggeredOnCheckTriggers_ActionFiresOnce,
    Test_TriggerOnceAfter_TriggerAfterEvent_ActionFiresOnce
  }
end
