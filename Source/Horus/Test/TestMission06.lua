skipMoose = true
dofile(baseDir .. "Horus/Mission06.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })

  for i = 1, 4 do
    local fobName = "FOB " .. i
    mock.moose:MockGroup({ name = fobName .. " SAM" })
    mock.moose:MockUnit({ name = fobName .. " Command" })
    mock.moose:MockGroup({ name = fobName .. " Tanks" })
    mock.moose:MockGroup({ name = fobName .. " Helos" })
  end

  for i = 1, 4 do
    local baseName = "Base " .. i
    mock.moose:MockGroup({ name = baseName .. " SAM" })
    mock.moose:MockUnit({ name = baseName .. " Command" })
    mock.moose:MockGroup({ name = baseName .. " Tanks" })
    mock.moose:MockGroup({ name = baseName .. " Helos" })
  end

  mock.moose:MockZone({ name = "Nalchik Park" })

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission06:New(args)

  return mock
end

local function Test_AllEnemyFobsDead_StateIsEnemyFobsDead()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.enemyFob[1].command:MockKill()
  mock.mission.enemyFob[2].command:MockKill()
  mock.mission.enemyFob[3].command:MockKill()
  mock.mission.enemyFob[4].command:MockKill()

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission06.State.EnemyFobsDead,
    "Expected state to be: Enemy FOBs dead")

end

local function Test_EnemyFobsDeadStateAndPlayersParked_StateIsMissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission06.State.EnemyFobsDead
  mock.mission.UnitsAreParked = function() return true end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionAccomplished,
    "Expected state to be: Mission accomplished")

end

local function Test_FriendlyBaseDestroyed_StateIsMissionFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.mission.friendlyBase[1].command:MockKill()

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionFailed,
    "Expected state to be: Mission failed")

end

function Test_Mission06()
  return RunTests {
    "Mission06",
    Test_AllEnemyFobsDead_StateIsEnemyFobsDead,
    Test_EnemyFobsDeadStateAndPlayersParked_StateIsMissionAccomplished,
    Test_FriendlyBaseDestroyed_StateIsMissionFailed
  }
end

--testOnly = Test_Mission06
