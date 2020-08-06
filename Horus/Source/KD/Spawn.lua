---
-- @module KD.Spawn

--- 
-- @type Spawn
-- @extends KD.Object#Object

---
-- @field #Spawn
Spawn = Object:_New {
  spawners = {},
  mission = nil,
  spawnerCount = 3,
  migsNextSpawner = 1,
  maxUnitsFunc = nil,
  migsSpawnInitCount = 0,
  groupSize = 2, -- pairs in ME
  migsSpawnVariation = .5,
  migsSpawnStart = 60,
  migsSpawnSeparation = 300,
}

---
-- @param #Spawn self
-- @param Mission#Mission mission
-- @param #number spawnerCount
-- @param #function maxUnitsFunc
-- @param #number groupSize
-- @return #Spawn
function Spawn:New(mission, spawnerCount, maxUnitsFunc, groupSize)
  local o = self:_New(nil)
  o.mission = mission
  o.spawnerCount = spawnerCount
  o.maxUnitsFunc = maxUnitsFunc
  o.groupSize = groupSize
  
  o:SetTraceOn(true)
  o:SetTraceLevel(3)
  o:SetAssert(true)
  
  return o
end

---
-- @param #Spawn self
-- @param #table o
-- @return #Spawn
function Spawn:_New(o)
  local o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

---
-- @param #Spawn self
function Spawn:StartSpawnEnemies()
  self:Assert(self.mission, "Field: mission cannot be nil")
  self:Assert(self.maxUnitsFunc, "Field: maxUnitsFunc cannot be nil")
  
  self:Trace(2, "Setting up MiG spawners")
  
  for i = 1, self.spawnerCount do
    
    local spawn = SPAWN:New("MiG " .. i)
    spawn.id = i
    self.mission:AddSpawner(spawn)
    self.spawners[#self.spawners + 1] = spawn
    
  end
  
  self:ShuffleList(self.spawners)
  
  SCHEDULER:New(
    nil, function() self:SpawnTick() end, {},
    self.migsSpawnStart, self.migsSpawnSeparation, self.migsSpawnVariation)
end

---
-- @param #Spawn self
function Spawn:SpawnTick()
  self.migsNextSpawner = _inc(self.migsNextSpawner)
  if (self.migsNextSpawner > #self.spawners) then
    self.migsNextSpawner = 1
  end
  
  local spawn = self.spawners[self.migsNextSpawner]
  local maxMigs = self.maxUnitsFunc(self.mission)
  
  self:Trace(2, "MiG spawn tick, id=" .. spawn.id .. " max=" .. maxMigs .. " count=" .. self.migsSpawnInitCount)
  
  if (self.migsSpawnInitCount < maxMigs) then
    
    -- spawns a pair
    self:Trace(2, "MiG spawn, id=" .. spawn.id)
    spawn:Spawn()
    
    -- increment here instead of OnUnitSpawn to prevent race condition, since
    -- events happen only on game tick
    self.migsSpawnInitCount = self.migsSpawnInitCount + self.groupSize
    
  end
end
