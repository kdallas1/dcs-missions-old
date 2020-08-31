skipMoose = true
dofile(baseDir .. "Horus/Mission09.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })
  
  mock.moose:MockZone({ name = "Mineralnye Vody Park" })
  
  mock.enemyCommand1 = mock.moose:MockGroup({ name = "Enemy Command #001" })
  mock.enemyCommand2 = mock.moose:MockGroup({ name = "Enemy Command #002" })
  mock.moose:MockGroup({ name = "Enemy Soldiers" })
  mock.moose:MockGroup({ name = "Enemy Tanks" })
  mock.moose:MockGroup({ name = "Enemy Helos" })
  mock.moose:MockGroup({ name = "Enemy Jets" })
  mock.moose:MockGroup({ name = "Enemy AAA" })
  
  mock.friendlyCommand1 = mock.moose:MockGroup({ name = "Friendly Command #001" })
  mock.friendlyCommand2 = mock.moose:MockGroup({ name = "Friendly Command #002" })
  mock.moose:MockGroup({ name = "Friendly Soldiers" })
  mock.moose:MockGroup({ name = "Friendly Tanks" })
  mock.moose:MockGroup({ name = "Friendly Helos" })
  
  mock.enemySoldiers = mock.moose:MockSpawn({ SpawnTemplatePrefix = "Enemy Soldiers" })
  mock.friendlySoldiers = mock.moose:MockSpawn({ SpawnTemplatePrefix = "Friendly Soldiers" })

  mock.friendlySoldiers.SpawnCount = 1
  mock.enemySoldiers.SpawnCount = 1
  
  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission09:New(args)

  return mock
end

local function Test_OnlyOneEnemyCommandIsDead_StateIsNotEnemyCommandDead()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
  })

  mock.mission:Start()
  
  mock.enemyCommand1:MockKill()
  
  mock.mission:GameLoop()
  
  TestAssert(
    mock.mission.state.current == MissionState.MissionStarted, 
    "Expected state to be: Mission started")

end

local function Test_BothEnemyCommandsAreDead_StateIsEnemyCommandDead()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
  })

  mock.mission:Start()
  
  mock.enemyCommand1:MockKill()
  mock.enemyCommand2:MockKill()
  mock.mission.CountAliveUnitsFromSpawn = function() return 1 end
  
  mock.mission:GameLoop()
  
  TestAssertEqual(
    Mission09.State.EnemyCommandDead,
    mock.mission.state.current,
    "mission state",
    function(v) return mock.mission.state:GetStateName(v) end)

end

local function Test_BothEnemyCommandsAreDead_SpawnSchedulesStopped()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
  })
  
  local stopCalled = false
  mock.enemySoldiers.SpawnScheduleStop = function() stopCalled = true end

  mock.mission:Start()
  
  mock.enemyCommand1:MockKill()
  mock.enemyCommand2:MockKill()
  
  mock.mission:GameLoop()

  TestAssert(stopCalled, "Expected stop scheduler to be called on enemy soldier spawner.")
  
end

local function Test_BothFriendlyCommandsAreDead_SpawnSchedulesStopped()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
  })
  
  local stopCalled = false
  mock.friendlySoldiers.SpawnScheduleStop = function() stopCalled = true end

  mock.friendlyCommand1.aliveCount = 0
  mock.friendlyCommand2.aliveCount = 0

  local unit = mock.moose:MockUnit({
    name = "Friendly Command"
  })

  mock.mission:OnUnitDead(unit)

  TestAssert(stopCalled, "Expected stop scheduler to be called on friendly soldier spawner.")
    
end

local function Test_EnemyCommandDeadAndEnemySoldiersAreDead_StateIsEnemySoldiersDead()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
  })

  mock.mission:Start()
  
  mock.mission.state.current = Mission09.State.EnemyCommandDead
  mock.enemySoldiers.SpawnCount = 0
  
  mock.mission:GameLoop()
  
  TestAssert(
    mock.mission.state.current == Mission09.State.EnemySoldiersDead, 
    "Expected state to be: Enemy soldiers dead")

end

local function Test_PlayersLandedAndEnemyCommandDead_StateIsMissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 3 },
  })

  mock.mission:Start()
  
  mock.mission.state.current = Mission09.State.EnemySoldiersDead
  mock.mission.UnitsAreParked = function() return true end
  
  mock.mission:GameLoop()
  
  TestAssert(
    mock.mission.state.current == MissionState.MissionAccomplished, 
    "Expected state to be: Mission accomplished")

end

function Test_Mission09()
  return RunTests {
    "Mission09",
    Test_OnlyOneEnemyCommandIsDead_StateIsNotEnemyCommandDead,
    Test_BothEnemyCommandsAreDead_StateIsEnemyCommandDead,
    Test_BothEnemyCommandsAreDead_SpawnSchedulesStopped,
    Test_BothFriendlyCommandsAreDead_SpawnSchedulesStopped,
    Test_EnemyCommandDeadAndEnemySoldiersAreDead_StateIsEnemySoldiersDead,
    Test_PlayersLandedAndEnemyCommandDead_StateIsMissionAccomplished,
  }
end

--testOnly = Test_Mission09
