dofile(baseDir .. "KD/Events.lua")

---
-- @module KD.StateMachine

--- 
-- @type StateMachine
-- @extends KD.Events#Events
StateMachine = {
  className = "StateMachine",
  
  current = nil,
  finalState = nil
}

--- 
-- @type State
-- @extends KD.Event#Event
State = { }

-- Keep track of state IDs
local _stateCount = 0

function State:NextState()
  local state = _stateCount 
  _stateCount = _stateCount +1
  return state
end

---
-- @function [parent=#StateMachine] New
-- @param #StateMachine self
-- @return #StateMachine

---
-- @param #StateMachine self
function StateMachine:StateMachine()

  self.onceStates = {}
  self.onceTriggers = {}
  self.depends = {}
  self.finals = {}
  
end

--- Register a trigger which changes the state and fires an action.
-- @param #StateMachine self
function StateMachine:TriggerOnce(state, trigger, action)

  self:Assert(state, "Arg `state` was nil")
  self:Assert(trigger, "Arg `trigger` was nil")
  
  self.onceStates[state] = false
  self.onceTriggers[state] = trigger

  if (action) then
    self:HandleEvent(state, action)
  end
  
end

--- Register an action that happens the first time `Change` is called,
-- but only from a specific state.
-- @param #StateMachine self
function StateMachine:TriggerOnceAfter(state, after, trigger, action)

  self:Assert(state, "Arg `state` was nil")
  self:Assert(after, "Arg `state` was nil")
  self:Assert(trigger, "Arg `state` was nil")
  
  self:TriggerOnce(state, trigger, action)
  self.depends[state] = after
  
end

--- Register an action that happens the first time `Change` is called.
-- @param #StateMachine self
function StateMachine:ActionOnce(state, action)

  self:Assert(state, "Arg `state` was nil")
  self:Assert(action, "Arg `action` was nil")
  
  self.onceStates[state] = false
  self:HandleEvent(state, action)
  
end

--- Changes the state to change which fires the registered action.
-- @param #StateMachine self
-- @param #State state
function StateMachine:Change(state)

  self:Assert(state, "Arg `state` was nil")
  
  if (self.finalState) then
    self:Trace(3, "Already at final state: " .. self.finalState)
    return
  end
    
  if (self.onceStates[state] ~= nil) then
    if (self.onceStates[state] == false) then

      self:Trace(3, "Current state changed to: " .. state)
      self.current = state
      
      self:FireEvent(state)
      self.onceStates[state] = true
      
      if self.finals[state] then
        self.finalState = state
      end
      
      return true
    else
      self:Trace(3, "Once state already called, state=" .. state)
    end
  end
  
  return false
  
end

--- 
-- @param #StateMachine self
function StateMachine:CheckTriggers()

  for state, trigger in pairs(self.onceTriggers) do
    
    -- check trigger only up until we need to change to the state 
    if ((self.onceStates[state] ~= nil) and (self.onceStates[state] == false)) then
      local canTrigger = true
      
      local dependsOnState = self.depends[state] 
      if (dependsOnState) then
        canTrigger = (self.current == dependsOnState)
      end
      
      if canTrigger then

        local triggerResult = trigger()
        self:Assert(triggerResult ~= nil, "Trigger return value must not be nil")
        self:AssertType(triggerResult, "boolean")

        if triggerResult then

          local changed = self:Change(state)
          if not changed then
            self:Trace(3, "Change could not be triggered, state=" .. state)
          end

        end

      end
      
    end
    
  end
  
end

--- Sets a state as final, once this state is reached, no going back.
-- @param #StateMachine self
function StateMachine:SetFinal(state)

  self:Assert(state, "Arg `state` was nil")
  self.finals[state] = true
  
end

--- 
-- @param #StateMachine self
function StateMachine:IsFinalState()

  return self.finalState ~= nil
  
end

StateMachine = createClass(Events, StateMachine)
