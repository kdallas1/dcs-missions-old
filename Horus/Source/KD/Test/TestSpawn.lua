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
  
  local mockSpawn = {}
  mockSpawn.AddSpawner = function() end
  
  local spawnCount = 0
  spawn.mooseSpawn = {}
  spawn.mooseSpawn.New = function() 
    spawnCount = _inc(spawnCount)
    return {} 
  end
  
  spawn.mooseScheduler = {}
  spawn.mooseScheduler.New = function() end
  
  spawn:StartSpawnEnemies()
  
  TestAssert(spawnCount == 2, "Expected 2 spawn calls")
  TestAssert(#spawn.spawners == 2, "Expected 2 spawn objects")
  
  return true
  
end

function Test_Spawn()
  return RunTests {
    Test_StartSpawnEnemies_SchedulerCalled,
    Test_StartSpawnEnemies_TwoSpawnsCreated
  }
end
