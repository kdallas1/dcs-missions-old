skipMoose = true
dofile(baseDir .. "Horus/Mission05.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)

  mock.friendlyHelo1 = mock.moose:MockUnit({ name = "Friendly Helo #001", life = 20 })
  mock.friendlyHelo2 = mock.moose:MockUnit({ name = "Friendly Helo #002", life = 20 })
  
  mock.friendlyHeloGroup = mock.moose:MockGroup(
    {
      name = "Friendly Helos", 
      units = { mock.friendlyHelo1, mock.friendlyHelo2 },
      aliveCount = 2
    }
  )

  mock.enemySams = mock.moose:MockGroup({ name = "Enemy SAMs", aliveCount = 2 })

  mock.nalchikParkZone = mock.moose:MockZone({ name = "Nalchik Park" })
  mock.landingZone = mock.moose:MockZone({ name = "Landing" })
  mock.beslanZone = mock.moose:MockZone({ name = "Beslan" })

  mock.c4 = {}
  mock.c4[1] = mock.moose:MockStatic({ name = "C4 #001" })
  mock.c4[2] = mock.moose:MockStatic({ name = "C4 #002" })

  mock.enemyAaa = {}
  mock.enemyAaa[1] = mock.moose:MockGroup({ name = "Enemy AAA #001", aliveCount = 2 })
  mock.enemyAaa[2] = mock.moose:MockGroup({ name = "Enemy AAA #002", aliveCount = 2 })
  mock.enemyAaa[3] = mock.moose:MockGroup({ name = "Enemy AAA #003", aliveCount = 2 })
  mock.enemyAaa[4] = mock.moose:MockGroup({ name = "Enemy AAA #004", aliveCount = 2 })
  mock.enemyAaa[5] = mock.moose:MockGroup({ name = "Enemy AAA #005", aliveCount = 2 })
  mock.enemyAaa[6] = mock.moose:MockGroup({ name = "Enemy AAA #006", aliveCount = 2 })

  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission05:New(args)

  return mock
end

local function Test_FriendlyHelosAlive_MissionNotFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  TestAssert(
    mock.mission.state.current ~= MissionState.MissionFailed,
    "Mission state should not be failed")

end

local function Test_OneFriendlyHeloStillAlive_MissionNotFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.friendlyHeloGroup.aliveCount = 1

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current ~= MissionState.MissionFailed,
    "Mission state should not be failed")

end

local function Test_AllFriendlyHelosDead_MissionFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.friendlyHeloGroup:MockKill()
  
  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionFailed,
    "Mission state should be failed")

end

local function Test_OnSamsDestroyed_HelosProceedFlagSet()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })
  
  local activateCalled = false
  mock.friendlyHeloGroup.Activate = function() activateCalled = true end

  mock.mission:Start()

  mock.enemySams.aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(activateCalled, "Expected helos to be activated")

end

local function Test_FriendlyHelosLanded_C4ExplodesAndStateIsBaseDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.landingZone.IsVec3InZone = function() return true end

  mock.c4[1].GetCoordinate = function()
    return {
      Explosion = function() mock.c4[1].exploded = true end
    }
  end

  mock.c4[2].GetCoordinate = function()
    return {
      Explosion = function() mock.c4[2].exploded = true end
    }
  end

  mock.mission:GameLoop()

  TestAssert(mock.c4[1].exploded, "First C4 should have exploded")
  TestAssert(mock.c4[2].exploded, "Second C4 should have exploded")
  TestAssert(
    mock.mission.state.current == Mission05.State.EnemyBaseDestroyed,
    "State should be: Enemy base destroyed"
  )

end

local function Test_EnemyBaseDestroyed_EnemyAaaActivates()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.enemyAaa[1].Activate = function() aaa1 = true end
  mock.enemyAaa[2].Activate = function() aaa2 = true end
  mock.enemyAaa[3].Activate = function() aaa3 = true end
  mock.enemyAaa[4].Activate = function() aaa4 = true end
  mock.enemyAaa[5].Activate = function() aaa5 = true end
  mock.enemyAaa[6].Activate = function() aaa6 = true end

  mock.mission.state:Change(Mission05.State.EnemyBaseDestroyed)

  mock.mission:GameLoop()

  TestAssert(aaa1, "AAA 1 should have activated")
  TestAssert(aaa2, "AAA 2 should have activated")
  TestAssert(aaa3, "AAA 3 should have activated")
  TestAssert(aaa4, "AAA 4 should have activated")
  TestAssert(aaa5, "AAA 5 should have activated")
  TestAssert(aaa6, "AAA 6 should have activated")

end

local function Test_HalfEnemyAaaUnitsDead_StateChangedToEnemyAaaDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local flagSet = nil
  local flagValue = nil
  mock.mission.SetFlag = function(self, flag, value)
    flagSet = flag
    flagValue = value
  end

  mock.friendlyHeloGroup.IsNotInZone = function() return false end

  mock.mission:Start()

  mock.mission.state.current = Mission05.State.EnemyBaseDestroyed

  mock.enemyAaa[1].aliveCount = 0
  mock.enemyAaa[2].aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission05.State.EnemyAaaDestroyed, 
    "State should be: Enemy AAA destroyed")

  TestAssert(
    flagSet == Mission05.Flags.FriendlyHelosRTB,
    "Flag should be: Friendly helos RTB")

  TestAssert(flagValue, "Flag should be true")

end

local function Test_OneEnemyAaaUnitsDead_StateNotChangedToEnemyAaaDestroyed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local flagSet = nil
  local flagValue = nil
  mock.mission.SetFlag = function(self, flag, value)
    flagSet = flag
    flagValue = value
  end

  mock.friendlyHeloGroup.IsNotInZone = function() return false end

  mock.mission:Start()

  mock.mission.state.current = Mission05.State.EnemyBaseDestroyed

  mock.enemyAaa[1].aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current ~= Mission05.State.EnemyAaaDestroyed, 
    "State should not be: Enemy AAA destroyed")

  TestAssert(
    flagSet ~= Mission05.Flags.FriendlyHelosRTB,
    "Flag should not be: Friendly helos RTB")

  TestAssert(not flagValue, "Flag should not be true")

end

local function Test_EnemyAaaDestroyedStateAndHelosEscaped_FriendlyHelosEscapedState()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission05.State.EnemyAaaDestroyed
  mock.friendlyHeloGroup.IsNotInZone = function() return true end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == Mission05.State.FriendlyHelosEscaped,
    "State should be: Friendly helos escaped")

end

local function Test_FriendlyHelosEscapedAndPlayersRTB_MissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  mock.mission.state.current = Mission05.State.FriendlyHelosEscaped
  mock.mission.UnitsAreParked = function(self, zone, units)
    return (zone == mock.nalchikParkZone)
  end

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionAccomplished,
    "State should be: Mission accomplished")

end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_FriendlyHelosAlive_MissionNotFailed,
    Test_OneFriendlyHeloStillAlive_MissionNotFailed,
    Test_AllFriendlyHelosDead_MissionFailed,
    Test_OnSamsDestroyed_HelosProceedFlagSet,
    Test_FriendlyHelosLanded_C4ExplodesAndStateIsBaseDestroyed,
    Test_EnemyBaseDestroyed_EnemyAaaActivates,
    Test_HalfEnemyAaaUnitsDead_StateChangedToEnemyAaaDestroyed,
    Test_OneEnemyAaaUnitsDead_StateNotChangedToEnemyAaaDestroyed,
    --Test_EnemyAaaDestroyedStateAndHelosEscaped_FriendlyHelosEscapedState,
    Test_FriendlyHelosEscapedAndPlayersRTB_MissionAccomplished
  }
end

--testOnly = Test_Mission05
