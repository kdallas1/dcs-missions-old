dofile(baseDir .. "KD/Object.lua")

---
-- @module KD.Events

--- 
-- @type Events
-- @extends KD.Object#Object
Events = {
  className = "Events",
  
  ---@field #list<#function> eventHandlers
  eventHandlers = nil,
}

---
-- @type Event
Event = { }

---
-- @function [parent=#Events] New
-- @param #Events self
-- @return #Events

--- 
-- @param #Events self
function Events:Events()

  self.eventHandlers = {}
  
end

---
-- @param #MissionEvents self
-- @param #Event event
-- @param #function handler
function Events:HandleEvent(event, handler)
  self:Assert(event, "Arg `event` was nil")
  self:Assert(handler, "Arg `handler` was nil")
  self.eventHandlers[event] = handler
  self:Trace(3, "Event handler added, total=" .. #self.eventHandlers)
end

---
-- @param #MissionEvents self
-- @param #Event event
function Events:FireEvent(event, arg)
  self:Assert(event, "Arg `event` was nil")
  local eventHandler = self.eventHandlers[event]
  if eventHandler then
    eventHandler(arg)
  end
end

Events = createClass(Object, Events)
