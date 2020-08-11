dofile(baseDir .. "KD/Events.lua")

---
-- @module KD.StateMachine

--- 
-- @type StateMachine
-- @extends KD.Events#Events
StateMachine = {
  className = "StateMachine",
  
  current = nil
}

--- 
-- @type State
-- @extends KD.Event#Event
State = { }

---
-- @function [parent=#StateMachine] New
-- @param #StateMachine self
-- @return #StateMachine

---
-- @param #StateMachine self
function StateMachine:StateMachine()

  --- @field #table<#State, #boolean> onceStates
  self.onceStates = {}
  
end

function StateMachine:AddOnce(state, handler)
  self:Assert(state, "Arg `state` was nil")
  
  self.onceStates[state] = false
  self:HandleEvent(state, handler)
  
end

---
-- @param #StateMachine self
-- @param #State state
function StateMachine:Change(state)
  self:Assert(state, "Arg `state` was nil")
  
  if (self.onceStates[state] ~= nil) then
    if (self.onceStates[state] == false) then
      self.current = state
      self:FireEvent(state)
      self.onceStates[state] = true
      return true
    else
      self:Trace(3, "Once state already called, key=" .. state)
    end
  end
  
  return false
end

StateMachine = createClass(Events, StateMachine)
