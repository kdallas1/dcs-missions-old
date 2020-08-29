dofile(baseDir .. "KD/Events.lua")

---
-- @module KD.MissionEvents

--- 
-- @type MissionEvents
-- @extends KD.Events#Events
MissionEvents = {
  className = "MissionEvents"
}

---
-- @function [parent=#MissionEvents] New
-- @param #MissionEvents self
-- @return #MissionEvents

---
-- @type MissionEvent
-- @extends KD.Event#Event
MissionEvent = {
  Spawn     = Event:NextEvent(),
  Damaged   = Event:NextEvent(),
  Dead      = Event:NextEvent(),
}

---
-- @param #MissionEvents self
function MissionEvents:MissionEvents()
  
  self.units = {}
  
end

---
-- @param #MissionEvents self
-- @param Wrapper.Unit#UNIT unit
function MissionEvents:TryAddUnit(unit)
  
  local id = unit:GetName()
  if not self.units[id] then
    self.units[id] = unit
    self:Trace(3, "Firing unit spawn event: " .. unit:GetName())
    self:FireEvent(MissionEvent.Spawn, unit)
  end
end

---
-- @param #MissionEvents self
-- @param #list<Wrapper.Unit#UNIT> units
function MissionEvents:UpdateFromUnitList(units)
  for i = 1, #units do
    self:TryAddUnit(units[i])
  end
end

---
-- @param #MissionEvents self
function MissionEvents:CheckUnitList()

  self:Trace(3, "Checking unit list")
  
  for id, unit in pairs(self.units) do
    self:CheckUnit(unit)
  end
end

---
-- @param #MissionEvents self
-- @param Wrapper.Unit#UNIT unit
function MissionEvents:CheckUnit(unit)
  
  local life = unit:GetLife()
  local fireDieEvent = false
  self:Trace(3, "Checking unit: " .. unit:GetName() .. ", health " .. tostring(life))
  
  -- we can't use IsAlive here, because the unit may not have spawned yet.
  -- previously using the EVENTS.Crash event, but it was a bit unreliable
  if ((life <= 1) and (not unit.eventDeadFired)) then
    self:Trace(3, "Firing unit dead event: " .. unit:GetName())
    self:FireEvent(MissionEvent.Dead, unit)
    unit.eventDeadFired = true
  end
end

---
-- @param #MissionEvents self
-- @param Wrapper.Group#GROUP group
function MissionEvents:UpdateFromGroup(group)

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
-- @param #MissionEvents self
-- @param #list<Wrapper.Group#GROUP> groups
function MissionEvents:UpdateFromGroupList(groups)

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
-- @param #MissionEvents self
-- @param #list<Core.Spawn#SPAWN> spawners
function MissionEvents:UpdateFromSpawnerList(spawners)

  self:Trace(3, "Checking spawner list")
  
  for i = 1, #spawners do
    local spawner = spawners[i]
    self:Trace(3, "Checking spawner, prefix='" .. spawner.SpawnTemplatePrefix .. "' count=" .. spawner.SpawnCount)
    
    local groups = {}
    for i = 1, spawner.SpawnCount do
    
      local group = spawner:GetGroupFromIndex(i)
      if group then
        self:Trace(3, "Adding group from spawner: " .. group:GetName())
        groups[#groups + 1] = group
      end
    end
    
    self:UpdateFromGroupList(groups)
  end
end

MissionEvents = createClass(Events, MissionEvents)
