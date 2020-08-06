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
  nextSpawner = 1,
  maxUnitsFunc = nil,
  spawnInitCount = 0,
  spawnVariation = .5,
  spawnStart = 60,
  spawnSeparation = 300,
  mooseSpawn = SPAWN,
  mooseScheduler = SCHEDULER
}

---
-- @param #Spawn self
-- @param Mission#Mission mission
-- @param #number spawnerCount
-- @param #function maxUnitsFunc
-- @param #number groupSize
-- @return #Spawn
function Spawn:New(mission, spawnerCount, maxUnitsFunc, groupSize, prefix)
  local o = self:_New(nil)
  o.mission = mission
  o.spawnerCount = spawnerCount
  o.maxUnitsFunc = maxUnitsFunc
  o.groupSize = groupSize
  o.prefix = prefix
  
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
  
  self:Trace(2, "Setting up spawners: " .. self.prefix)
  
  for i = 1, self.spawnerCount do
    
    local spawn = self.mooseSpawn:New(self.prefix .. " " .. i)
    spawn.id = i
    self.mission:AddSpawner(spawn)
    self.spawners[#self.spawners + 1] = spawn
    
  end
  
  self:ShuffleList(self.spawners)
  
  self.mooseScheduler:New(
    nil, function() self:SpawnTick() end, {},
    self.spawnStart, self.spawnSeparation, self.spawnVariation)
end

---
-- @param #Spawn self
function Spawn:SpawnTick()
  self.nextSpawner = _inc(self.nextSpawner)
  if (self.nextSpawner > #self.spawners) then
    self.nextSpawner = 1
  end
  
  local spawn = self.spawners[self.nextSpawner]
  local maxMigs = self.maxUnitsFunc(self.mission)
  
  self:Trace(2, "Spawn tick, id=" .. spawn.id .. " max=" .. maxMigs .. " count=" .. self.spawnInitCount)
  
  if (self.spawnInitCount < maxMigs) then
    
    -- spawns a pair
    self:Trace(2, "Spawn, id=" .. spawn.id)
    spawn:Spawn()
    
    -- increment here instead of OnUnitSpawn to prevent race condition, since
    -- events happen only on game tick
    self.spawnInitCount = self.spawnInitCount + self.groupSize
    
  end
end
