dofile(baseDir .. "KD/Object.lua")

---
-- @module KD.Events

--- 
-- @type Events
-- @extends KD.Object#Object
Events = {
  className = "Events",
  
  ---@field #list<Wrapper.Unit#UNIT> units
  units = nil,
  
  ---@field #list<#function> eventHandlers
  eventHandlers = nil,
}

---
-- @function [parent=#Events] New
-- @param #Events self
-- @return #Events

Events = createClass(Events, Object)

---
-- @type Event
Event = {
  Spawn     = 0,
  Damaged   = 1,
  Dead      = 2,
}

function Events:Events()
  
  self.units = {}
  self.eventHandlers = {}
  
end

---
-- @param #Events self
-- @param #Event event
-- @param #function handler
function Events:HandleEvent(event, handler)
  self.eventHandlers[event] = handler
  self:Trace(3, "Event handler added, total=" .. #self.eventHandlers)
end

---
-- @param #Events self
-- @param #Event event
function Events:FireEvent(event, arg)
  local f = self.eventHandlers[event]
  if f then
    f(arg)
  end
end

---
-- @param #Events self
-- @param Wrapper.Unit#UNIT unit
function Events:TryAddUnit(unit)
  
  local id = unit:GetName()
  if not self.units[id] then
    self.units[id] = unit
    self:Trace(3, "Firing unit spawn event: " .. unit:GetName())
    self:FireEvent(Event.Spawn, unit)
  end
end

---
-- @param #Events self
-- @param #list<Wrapper.Unit#UNIT> units
function Events:UpdateFromUnitList(units)
  for i = 1, #units do
    self:TryAddUnit(units[i])
  end
end

---
-- @param #Events self
function Events:CheckUnitList()

  self:Trace(3, "Checking unit list")
  
  for id, unit in pairs(self.units) do
    self:CheckUnit(unit)
  end
end

---
-- @param #Events self
-- @param Wrapper.Unit#UNIT unit
function Events:CheckUnit(unit)
  
  local life = unit:GetLife()
  local fireDieEvent = false
  self:Trace(3, "Checking unit: " .. unit:GetName() .. ", health " .. tostring(life))
  
  -- we can't use IsAlive here, because the unit may not have spawned yet.
  -- previously using the EVENTS.Crash event, but it was a bit unreliable
  if ((life <= 1) and (not unit.eventDeadFired)) then
    self:Trace(3, "Firing unit dead event: " .. unit:GetName())
    self:FireEvent(Event.Dead, unit)
    unit.eventDeadFired = true
  end
end

---
-- @param #Events self
-- @param Wrapper.Group#GROUP group
function Events:UpdateFromGroup(group)

  self:Trace(3, "Checking group: " .. group:GetName())
  
  local units = group:GetUnits()
  if units then
    
    self:Trace(3, "Unit count: " .. #units)
    
    for i = 1, #units do
      
      -- add all units to our own list so we can watch units come and go
      local unit = units[i]
      
      self:Trace(3, "Checking unit: " .. unit:GetName())
      self:TryAddUnit(unit)
    end
  end
end

---
-- @param #Events self
-- @param #list<Wrapper.Group#GROUP> groups
function Events:UpdateFromGroupList(groups)

  self:Trace(3, "Checking group list")
  
  -- check internal groups list by default
  if not groups then
    groups = self.groups
  end
  
  for i = 1, #groups do
    local group = groups[i]
    if group then
      self:UpdateFromGroup(group)
    end
  end
end

---
-- @param #Events self
-- @param #list<Core.Spawn#SPAWN> spawners
function Events:UpdateFromSpawnerList(spawners)

  self:Trace(3, "Checking spawner list")
  
  for i = 1, #spawners do
    local spawner = spawners[i]
    self:Trace(3, "Checking spawner: " .. tostring(i))
    
    local groups = {}
    for i = 1, spawner.SpawnCount do
    
      local group = spawner:GetGroupFromIndex(i)
      if group then
        groups[#groups + 1] = group
      end
    end
    
    self:UpdateFromGroupList(groups)
  end
end
