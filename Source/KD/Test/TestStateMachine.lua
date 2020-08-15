dofile(baseDir .. "KD/StateMachine.lua")

---
-- @type TestState
-- @extends KD.State#State
local TestState = {
  TestState1 = 0,
  TestState2 = 1,
  TestState3 = 2,
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

local function Test_Change_ChangeCalled_CurrentIsCorrect()
  local sm = StateMachine:New()
  
  local s1Calls = 0
  local s2Calls = 0
  sm:ActionOnce(TestState.TestState1, function() s1Calls = s1Calls + 1 end)
  sm:ActionOnce(TestState.TestState2, function() s2Calls = s2Calls + 1 end)
  
  local result1 = sm:Change(TestState.TestState1)
  local currentAfterS1 = sm.current
  local result2 = sm:Change(TestState.TestState2)
  local currentAfterS2 = sm.current
  
  TestAssert(s1Calls == 1, "Expected TestState1 to fire once, but called " .. s1Calls .. " time(s)")
  TestAssert(s2Calls == 1, "Expected TestState2 to fire once, but called " .. s2Calls .. " time(s)")
  TestAssert(result1, "Expected `Change` with TestState1 to return true on 1st call")
  TestAssert(result2, "Expected `Change` with TestState2 to return true on 2nd call")
  TestAssert(currentAfterS1 == TestState.TestState1, "Expected current to be TestState1 after 1st call")
  TestAssert(currentAfterS2 == TestState.TestState2, "Expected current to be TestState2 after 1st call")
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
  
  sm:ActionOnce(TestState.TestState1, function() end)
  sm:TriggerOnceAfter(
    TestState.TestState2,
    TestState.TestState1,
    function() return true end,
    function() calls = calls + 1 end
  )
  
  sm:CheckTriggers()
  local changed = sm:Change(TestState.TestState1)
  sm:CheckTriggers()
  sm:CheckTriggers()
  
  TestAssert(changed, "Expected change to TestState1 to happen")
  TestAssert(calls == 1, "Expected TestState2 to fire once, but called " .. calls .. " time(s)")
end

local function Test_TriggerOnceAfter_NotOnDependEvent_NoActionFired()
  local sm = StateMachine:New()
  
  local calls = 0
  
  sm:TriggerOnceAfter(
    TestState.TestState2,
    TestState.TestState1,
    function() return true end,
    function() calls = calls + 1 end
  )
  
  sm:Change(TestState.TestState3)
  sm:CheckTriggers()
  
  TestAssert(calls == 0, "Expected TestState2 to never fire, but called " .. calls .. " time(s)")
end

local function Test_SetFinal_FinalStateReached_NoChangesPossible()
  local sm = StateMachine:New()
  
  local calls = 0
  
  sm:ActionOnce(TestState.TestState1, function() calls = calls + 1 end)
  sm:ActionOnce(TestState.TestState2, function() calls = calls + 1 end)
  sm:SetFinal(TestState.TestState1)
  
  local result1 = sm:Change(TestState.TestState1)
  local result2 = sm:Change(TestState.TestState2)
  
  TestAssert(calls == 1, "Expected TestState1 to fire once, but called " .. calls .. " time(s)")
  TestAssert(result1, "Expected `Change` to return true on 1st call")
  TestAssert(not result2, "Expected `Change` to return false on 2nd call")
end

function Test_StateMachine()
  return RunTests {
    "StateMachine",
    Test_ActionOnce_ChangeCalledTwice_ActionFiresOnce,
    Test_Change_OnceStateNotAdded_NoEventFired,
    Test_Change_ChangeCalled_CurrentIsCorrect,
    Test_TriggerOnce_TriggerFalse_NoActionFired,
    Test_TriggerOnce_TriggeredOnCheckTriggers_ActionFiresOnce,
    Test_TriggerOnceAfter_TriggerAfterEvent_ActionFiresOnce,
    Test_TriggerOnceAfter_NotOnDependEvent_NoActionFired,
    Test_SetFinal_FinalStateReached_NoChangesPossible
  }
end
