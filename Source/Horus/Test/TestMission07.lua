skipMoose = true
dofile(baseDir .. "Horus/Mission07.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })

  mock.moose:MockZone({ name = "Mozdok Park" })

  mock.moose:MockGroup({ name = "Enemy Jets" })
  mock.enemyJets = mock.moose:MockSpawn({ SpawnTemplatePrefix = "Enemy Jets" })

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission07:New(args)

  mock.mission.CountAliveUnitsFromSpawn = function() return 1 end

  return mock
end

local function Test_AllEnemyJetsDead_StateIsEnemyJetsDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.CountAliveUnitsFromSpawn = function() return 0 end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission07.State.EnemyJetsDestroyed,
    "Expected state to be: Enemy jets destroyed"
  )

end

local function Test_StateIsEnemyJetsDestroyedAndPlayersLanded_StateIsMissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission07.State.EnemyJetsDestroyed
  mock.mission.UnitsAreParked = function() return true end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionAccomplished,
    "Expected state to be: Mission accomplished"
  )

end

local function Test_SpawnEnemyJets_MaxSpawnOne_OnlyOneSpawned()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  local spawnCount = 0
  mock.enemyJets.SpawnAtAirbase = function() spawnCount = spawnCount + 1 end

  mock.mission:SpawnEnemyJets(1)

  TestAssert(spawnCount == 1, "Expected 1 spawn, but got: " .. spawnCount)

end

local function Test_Start_SpawnToFillMissingUnits()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  local spawnCount = 0
  mock.enemyJets.SpawnAtAirbase = function() spawnCount = spawnCount + 1 end

  mock.mission:Start()

  TestAssert(spawnCount == 2, "Expected 2 spawns, but got: " .. spawnCount)

end

testOnly = Test_SpawnEnemyJets_NoMaxSpawn_SpawnToFillMissingUnits

function Test_Mission07()
  return RunTests {
    "Mission07",
    Test_AllEnemyJetsDead_StateIsEnemyJetsDestroyed,
    Test_StateIsEnemyJetsDestroyedAndPlayersLanded_StateIsMissionAccomplished,
    Test_SpawnEnemyJets_MaxSpawnOne_OnlyOneSpawned,
    Test_Start_SpawnToFillMissingUnits,
  }
end

--testOnly = Test_Mission07
