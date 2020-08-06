local function Test_StartSpawnEnemies_SchedulerCalled()
  
  local mission = {}
  local maxUnitsFunc = function() end
  local spawn = Spawn:New(mission, 0, maxUnitsFunc, 0, "Test")
  
  local schedulerCalled = false
  spawn.mooseScheduler = {}
  spawn.mooseScheduler.New = function() schedulerCalled = true end
  
  spawn:StartSpawnEnemies()
  
  TestAssert(schedulerCalled, "Scheduler not called")
  
  return true
  
end

local function Test_StartSpawnEnemies_TwoSpawnsCreated()
  
  local mission = {}
  mission.AddSpawner = function() end
  
  local maxUnitsFunc = function() end
  
  local spawn = Spawn:New(mission, 2, maxUnitsFunc, 0, "Test")
  
  local spawnCount = 0
  spawn.mooseSpawn = {}
  spawn.mooseSpawn.New = function() 
    spawnCount = _inc(spawnCount)
    return {} 
  end
  
  spawn.mooseScheduler = {}
  spawn.mooseScheduler.New = function() end
  
  spawn:StartSpawnEnemies()
  
  TestAssert(spawnCount == 2, "Expected 2 spawn objects created")
  TestAssert(#spawn.spawners == 2, "Expected 2 spawn objects saved")
  
  return true
  
end

local function Test_SpawnTick_SpawnsFour()
  
  local mission = {}
  mission.AddSpawner = function() end
  
  local maxUnitsFunc = function() return 4 end
  
  local spawn = Spawn:New(mission, 2, maxUnitsFunc, 2, "Test")
  
  local spawnCalls = 0
  local mockSpawn = {}
  mockSpawn.Spawn = function() spawnCalls = _inc(spawnCalls) end 
  
  local spawnCount = 0
  spawn.mooseSpawn = {}
  spawn.mooseSpawn.New = function() 
    spawnCount = _inc(spawnCount)
    return mockSpawn
  end
  
  spawn.mooseScheduler = {}
  spawn.mooseScheduler.New = function() end
  
  -- HACK: OO is broken, every test uses the same object (no copy is done in `New` function)
  spawn.spawners = {}
  
  spawn:StartSpawnEnemies()
  
  TestAssert(#spawn.spawners == 2, "Expected 2 spawn objects saved, got " .. #spawn.spawners)
  
  spawn:SpawnTick()
  spawn:SpawnTick()
  spawn:SpawnTick()
  
  TestAssert(spawnCalls == 2, "Expected 2 spawn calls")
  TestAssert(spawn.spawnInitCount == 4, "Expected 4 spawn count (2 groups)")
  
  return true
end

function Test_Spawn()
  return RunTests {
    Test_StartSpawnEnemies_SchedulerCalled,
    Test_StartSpawnEnemies_TwoSpawnsCreated,
    Test_SpawnTick_SpawnsFour
  }
end
