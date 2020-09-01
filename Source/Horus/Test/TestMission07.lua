skipMoose = true
dofile(baseDir .. "Horus/Mission07.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.playerGroup = mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })
  
  mock.playerGroup.IsCompletelyInZone = function() return false end

  mock.moose:MockZone({ name = "Mozdok Park" })
  mock.moose:MockZone({ name = "Mozdok Takeoff" })
  mock.moose:MockZone({ name = "Mozdok Activate" })

  mock.moose:MockGroup({ name = "Enemy Jets" })
  mock.enemyJetsSpawn = mock.moose:MockSpawn({ SpawnTemplatePrefix = "Enemy Jets" })
  mock.enemyJetsSpawn.SpawnAtAirbase = function() 
    return mock.moose:MockGroup({
      name = "Enemy Jet",
      GetVelocityKNOTS = function() return 0 end,
      IsAboveRunway = function() return false end,
      IsAnyInZone = function() return false end,
      RespawnAtCurrentAirbase = function()
        return mock.enemyJetsSpawn.SpawnAtAirbase()
      end
    })
  end

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

local function Test_AllPlayersInEnemyZone_StateIsEnemyJetsActive()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.playerGroup.IsCompletelyInZone = function() return true end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission07.State.EnemyJetsActive,
    "Expected state to be: EnemyJetsActive"
  )

end

local function Test_AllEnemyJetsDead_StateIsEnemyJetsDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission07.State.EnemyJetsActive
  mock.mission.CountAliveUnitsFromSpawn = function() return 0 end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission07.State.EnemyJetsDestroyed,
    "Expected state to be: EnemyJetsDestroyed"
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
    "Expected state to be: MissionAccomplished"
  )

end

local function Test_Start_SpawnToFillMissingUnits()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  local spawnCount = 0
  local f = mock.enemyJetsSpawn.SpawnAtAirbase
  mock.enemyJetsSpawn.SpawnAtAirbase = function(self)
    spawnCount = spawnCount + 1
    return f(self)
  end

  mock.mission:Start()

  TestAssert(spawnCount == 5, "Expected 5 spawns, but got: " .. spawnCount)

end

local function Test_GameLoop_EnemyJetDestroyed_EnemyJetsRemainIsValid()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })
  
  local message = "[None]"
  mock.mission.MessageAll = function(self, length, text)
    message = text
  end
  
  mock.mission.players = { {}, {} }
  
  local unit = mock.moose:MockUnit({
    name = "Enemy Jet"
  })
  mock.mission:OnUnitDead(unit)
  
  TestAssert(message == "Enemy Jet destroyed. Remaining: 9", "Did not expect message: " .. message)

end

function Test_Mission07()
  return RunTests {
    "Mission07",
    Test_AllPlayersInEnemyZone_StateIsEnemyJetsActive,
    Test_AllEnemyJetsDead_StateIsEnemyJetsDestroyed,
    Test_StateIsEnemyJetsDestroyedAndPlayersLanded_StateIsMissionAccomplished,
    Test_Start_SpawnToFillMissingUnits,
    Test_GameLoop_EnemyJetDestroyed_EnemyJetsRemainIsValid
  }
end

--testOnly = Test_Mission07
