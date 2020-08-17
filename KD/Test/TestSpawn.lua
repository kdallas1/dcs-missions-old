dofile(baseDir .. "KD/Spawn.lua")

local function Test_StartSpawnEnemies_SchedulerCalled()
  
  local mission = {}
  local maxUnitsFunc = function() end
  local spawn = Spawn:_New(mission, 0, maxUnitsFunc, 0, "Test")
  
  local schedulerCalled = false
  spawn.mooseScheduler = {}
  spawn.mooseScheduler.New = function() schedulerCalled = true end
  
  spawn:StartSpawnEnemies()
  
  TestAssert(schedulerCalled, "Scheduler not called")
  
end

local function Test_StartSpawnEnemies_TwoSpawnsCreated()
  
  local mission = {}
  mission.AddSpawner = function() end
  
  local maxUnitsFunc = function() end
  
  local spawn = Spawn:_New(mission, 2, maxUnitsFunc, 0, "Test")
  
  local spawnCount = 0
  spawn.mooseSpawn = {}
  spawn.mooseSpawn.New = function() 
    spawnCount = spawnCount + 1
    return {} 
  end
  
  spawn.mooseScheduler = {}
  spawn.mooseScheduler.New = function() end
  
  spawn:StartSpawnEnemies()
  
  TestAssert(spawnCount == 2, "Expected 2 spawn objects created")
  TestAssert(#spawn.spawners == 2, "Expected 2 spawn objects saved")
  
end

local function Test_SpawnTick_SpawnsFour()
  
  local mission = {}
  mission.AddSpawner = function() end
  
  local maxUnitsFunc = function() return 4 end
  
  local spawn = Spawn:_New(mission, 2, maxUnitsFunc, 2, "Test")
  
  local spawnCalls = 0
  local mockSpawn = {}
  mockSpawn.Spawn = function() spawnCalls = spawnCalls + 1 end 
  
  local spawnCount = 0
  spawn.mooseSpawn = {}
  spawn.mooseSpawn.New = function() 
    spawnCount = spawnCount + 1
    return mockSpawn
  end
  
  spawn.mooseScheduler = {}
  spawn.mooseScheduler.New = function() end
  
  spawn:StartSpawnEnemies()
  
  TestAssert(#spawn.spawners == 2, "Expected 2 spawn objects saved, got " .. #spawn.spawners)
  
  spawn:SpawnTick()
  spawn:SpawnTick()
  spawn:SpawnTick()
  
  TestAssert(spawnCalls == 2, "Expected 2 spawn calls")
  TestAssert(spawn.spawnInitCount == 4, "Expected 4 spawn count (2 groups)")
  
end

function Test_Spawn()
  return RunTests {
    "Spawn",
    Test_StartSpawnEnemies_SchedulerCalled,
    Test_StartSpawnEnemies_TwoSpawnsCreated,
    Test_SpawnTick_SpawnsFour
  }
end
