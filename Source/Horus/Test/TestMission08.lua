skipMoose = true
dofile(baseDir .. "Horus/Mission08.lua")
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
      units = { launcher, launcher }
    })

    launcher.group = launcherGroup

    mock.moose:MockGroup({ name = launcherSite .. " Ammo" })
    mock.moose:MockGroup({ name = launcherSite .. " Tanks" })
  end

  mock.moose:MockGroup({name = "Enemy Tanks" })
  mock.moose:MockGroup({name = "Enemy Command" })
  
  mock.moose:MockGroup({
    name = "Enemy SAMs",
    units = { mock.moose:MockUnit({ name = "Enemy SAM 1" }) }
  })

  mock.moose:MockZone({ name = "Nalchik Park" })

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission08:New(args)
  
  mock.mission.ScheduleLauncherInfo = function() end

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

local function Test_AllEnemySamsDead_StateIsEnemySamsDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.enemySams.aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission08.State.EnemySamsDestroyed,
    "Expected state to be: Enemy SAMs destroyed")

end

local function Test_AllEnemyCommandDead_StateIsEnemyCommandDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission08.State.EnemySamsDestroyed
  mock.mission.enemyCommand.aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission08.State.EnemyCommandDestroyed,
    "Expected state to be: Enemy Command destroyed")

end

local function Test_EnemySamsDestroyedAndPlayersLanded_MissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission08.State.EnemyCommandDestroyed
  mock.mission.UnitsAreParked = function() return true end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionAccomplished,
    "Expected state to be: Mission accomplished")

end

local function Test_SingleFriendlyLauncherDead_SoundPlays()
  
  local mock = NewMock({
--    trace = { _traceOn = true, _traceLevel = 4 },
  })
  
  local playSound = nil
  mock.mission.PlaySound = function(self, sound) playSound = sound end

  mock.mission:Start()
  
  mock.mission.launcherSiteList[1].launchers.aliveCount = 1
  mock.mission.launcherSiteList[1].launchers.units[1]:MockKill()
  
  mock.mission:GameLoop()

  TestAssert(playSound, "Expected sound to be played on single launcher dead")
  TestAssert(playSound == Sound.UnitLost, "Expected sound to be UnitLost")
end

local function Test_WholeFriendlyLauncherGroupDead_MessageShows()
  
  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })
  
  local messageAll = nil
  mock.mission.MessageAll = function(self, length, text) messageAll = text end

  mock.mission:Start()

  mock.mission.launcherSiteList[1].launchers.aliveCount = 0
  mock.mission.launcherSiteList[1].launchers.units[1]:MockKill()
  mock.mission.launcherSiteList[1].launchers.units[2]:MockKill()

  mock.mission:GameLoop()

  TestAssert(messageAll, "Expected message to be shown when whole launcher group dead")
  TestAssert(
    messageAll == "Launcher Site 1 has been defeated! Remaining sites: 3",
    "When whole launcher group dead, didn't expect: " .. messageAll)
  
end

local function Test_EngageNextSam_SAMsAliveToAttack_SetTaskCalled()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })
  
  local sams = mock.mission.enemySams:GetUnits()
  mock.mission.enemySams.GetFirstUnitAlive = function() return sams[1] end
  
  local setTaskCalled = false
  mock.mission.launcherSiteList[1].launchers.SetTask = function() setTaskCalled = true end

  mock.mission:EngageNextSam()

  TestAssert(setTaskCalled, "Expected SetTask to be called.")
  
end

function Test_Mission08()
  return RunTests {
    "Mission08",
    Test_AllLaunchersDead_StateIsMissionFailed,
    Test_AllEnemySamsDead_StateIsEnemySamsDestroyed,
    Test_AllEnemyCommandDead_StateIsEnemyCommandDestroyed,
    Test_EnemySamsDestroyedAndPlayersLanded_MissionAccomplished,
    Test_SingleFriendlyLauncherDead_SoundPlays,
    Test_WholeFriendlyLauncherGroupDead_MessageShows,
    Test_EngageNextSam_SAMsAliveToAttack_SetTaskCalled
  }
end

--testOnly = Test_Mission08
