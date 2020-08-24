skipMoose = true
dofile(baseDir .. "Horus/Source/Mission08.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  local player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.moose:MockGroup({ name = "Dodge Squadron", units = { player } })

  for i = 1, 4 do
    local launcherSite = "Site " .. i

    local launcher = mock.moose:MockUnit({
      name = launcherSite .. " Launcher #001"
    })

    local launcherGroup = mock.moose:MockGroup({ 
      name = launcherSite .. " Launchers",
      units = { launcher }
    })

    launcher.group = launcherGroup

    mock.moose:MockGroup({ name = launcherSite .. " Tanks" })
  end

  mock.moose:MockGroup({name = "Enemy Tanks" })

  mock.moose:MockZone({ name = "Nalchik Park" })

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission08:New(args)

  return mock
end

local function Test_AllLaunchersDead_StateIsMissionFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.launcherSiteList[1].launchers.aliveCount = 0
  mock.mission.launcherSiteList[2].launchers.aliveCount = 0
  mock.mission.launcherSiteList[3].launchers.aliveCount = 0
  mock.mission.launcherSiteList[4].launchers.aliveCount = 0

  mock.mission.launcherSiteList[1].launchers.units[1]:MockKill()
  mock.mission.launcherSiteList[2].launchers.units[1]:MockKill()
  mock.mission.launcherSiteList[3].launchers.units[1]:MockKill()
  mock.mission.launcherSiteList[4].launchers.units[1]:MockKill()

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionFailed,
    "Expected state to be: Mission failed")

end

local function Test_AllEnemyTanksDead_StateIsEnemyBaseDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.enemyTanks.aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission08.State.EnemyBaseDestroyed,
    "Expected state to be: Enemy base destroyed")

end

local function Test_EnemyBaseDestroyedAndPlayersLanded_MissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission08.State.EnemyBaseDestroyed
  mock.mission.UnitsAreParked = function() return true end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionAccomplished,
    "Expected state to be: Mission accomplished")

end

function Test_Mission08()
  return RunTests {
    "Mission08",
    Test_AllLaunchersDead_StateIsMissionFailed,
    Test_AllEnemyTanksDead_StateIsEnemyBaseDestroyed,
    Test_EnemyBaseDestroyedAndPlayersLanded_MissionAccomplished
  }
end

--testOnly = Test_Mission08
