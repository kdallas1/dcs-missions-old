skipMoose = true
dofile(baseDir .. "Horus/Mission07.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })

  mock.moose:MockZone({ name = "Nalchik Park" })

  mock.moose:MockGroup({ name = "Enemy Jet #001" })
  mock.moose:MockSpawn({ SpawnTemplatePrefix = "Enemy Jet #001" })
  mock.moose:MockGroup({ name = "Enemy Jet #002" })
  mock.moose:MockSpawn({ SpawnTemplatePrefix = "Enemy Jet #002" })

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

local function Test_AllEnemyJetsDead_StateIsMissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.CountAliveUnitsFromSpawn = function() return 0 end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionAccomplished,
    "Expected state to be: Mission accomplished"
  )

end

function Test_Mission07()
  return RunTests {
    "Mission07",
    Test_AllEnemyJetsDead_StateIsMissionAccomplished
  }
end

--testOnly = Test_Mission07
