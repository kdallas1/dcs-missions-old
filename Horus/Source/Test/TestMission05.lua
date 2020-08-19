skipMoose = true
dofile(baseDir .. "Horus/Source/Mission05.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  local moose = MockMoose:New(fields)
  mock.moose = moose

  mock.friendlyHelo1 = moose:MockUnit({ name = "Friendly Helo #001", life = 10 })
  mock.friendlyHelo2 = moose:MockUnit({ name = "Friendly Helo #002", life = 10 })
  
  mock.friendlyHeloGroup = moose:MockGroup(
    {
      name = "Friendly Helos", 
      units = { mock.friendlyHelo1, mock.friendlyHelo2 },
      aliveCount = 2
    }
  )

  mock.enemySams = moose:MockGroup({ name = "Enemy SAMs", aliveCount = 2 })
  mock.landingZone = moose:MockZone({ name = "Landing" })
  mock.beslanZone = moose:MockZone({ name = "Beslan" })

  mock.c4 = {}
  mock.c4[1] = moose:MockStatic({ name = "C4 #001" })
  mock.c4[2] = moose:MockStatic({ name = "C4 #002" })

  mock.c4[1].GetCoordinate = function() return { Explosion = function() end } end
  mock.c4[2].GetCoordinate = function() return { Explosion = function() end } end

  mock.enemyAAA1 = moose:MockGroup({ name = "Enemy AAA #001", aliveCount = 2 })
  mock.enemyAAA2 = moose:MockGroup({ name = "Enemy AAA #002", aliveCount = 2 })
  mock.enemyAAA3 = moose:MockGroup({ name = "Enemy AAA #003", aliveCount = 2 })

  mock.enemyAAA1.Activate = function() end
  mock.enemyAAA2.Activate = function() end
  mock.enemyAAA3.Activate = function() end

  local dcs = MockDCS:New()
  mock.dcs = dcs

  dcs.unit.getByName = function() end

  local args = {
    trace = { _traceOn = false },
    moose = moose,
    dcs = dcs
  }

  if fields then
    for k, v in pairs(fields) do
      args[k] = v
    end
  end

  mock.mission = Mission05:New(args)

  return mock
end

-- TODO: move to mock Moose test (not specific to M5) 
local function Test_TraceOn_MockSchedulerTraceOn()

  local mock = NewMock({
    trace = { _traceOn = true, _traceLevel = 2 },
  })

  TestAssert(mock.moose.scheduler.trace, "Mock Moose scheduler trace should be on")

end

local function Test_FriendlyHelosAlive_MissionNotFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local mission = mock.mission

  mission:Start()

  TestAssert(
    mission.state.current ~= MissionState.MissionFailed,
    "Mission state should not be failed")

end

local function Test_OneFriendlyHeloStillAlive_MissionNotFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local mission = mock.mission

  mission:Start()

  mock.friendlyHeloGroup.aliveCount = 1

  mission:GameLoop()

  TestAssert(
    mission.state.current ~= MissionState.MissionFailed,
    "Mission state should not be failed")

end

local function Test_AllFriendlyHelosDead_MissionFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local mission = mock.mission

  mission:Start()

  mock.friendlyHeloGroup.aliveCount = 0
  
  mission:GameLoop()

  TestAssert(
    mission.state.current == MissionState.MissionFailed,
    "Mission state should be failed")

end

local function Test_OnSamsDestroyed_HelosProceedFlagSet()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 2 },
  })

  local flagSet = nil
  local flagValue = nil
  mock.mission.SetFlag = function(self, flag, value)
    flagSet = flag
    flagValue = value
  end

  mock.mission:Start()

  mock.enemySams.aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(
    flagSet == Mission05.Flags.FriendlyHelosAdvance,
    "Expected helo advance flag to be called")

  TestAssert(flagValue, "Expected helo advance flag to be set to true")

end

local function Test_FriendlyHelosLanded_C4Explodes()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local mission = mock.mission

  mission:Start()

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

  mission:GameLoop()

  TestAssert(mock.c4[1].exploded, "First C4 should have exploded")
  TestAssert(mock.c4[2].exploded, "Second C4 should have exploded")

end

local function Test_C4Exploded_EnemyAAAActivates()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local mission = mock.mission

  mission:Start()

  mock.landingZone.IsVec3InZone = function() return true end

  mock.enemyAAA1.Activate = function() aaa1 = true end
  mock.enemyAAA2.Activate = function() aaa2 = true end
  mock.enemyAAA3.Activate = function() aaa3 = true end

  mission:GameLoop()

  TestAssert(aaa1, "AAA 1 should have activated")
  TestAssert(aaa2, "AAA 2 should have activated")
  TestAssert(aaa3, "AAA 3 should have activated")

end

local function Test_EnemyAAADead_FriendlyHelosBeginEscape()

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

  mock.enemyAAA1.aliveCount = 0
  mock.enemyAAA2.aliveCount = 0
  mock.enemyAAA3.aliveCount = 0

  mock.mission:GameLoop()

  TestAssert(mock.mission.state.current == Mission05.State.EnemyAaaDestroyed, "State should be AAA destroyed")
  TestAssert(flagSet == Mission05.Flags.FriendlyHelosRTB, "Friendly helos flag should be RTB")
  TestAssert(flagValue, "Flag should be true")

end

--testOnly = Test_EnemyAAADead_FriendlyHelosBeginEscape

local function Test_FriendlyHelosEscapedAndPlayersRTB_MissionAccomplished()
end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_TraceOn_MockSchedulerTraceOn,
    Test_FriendlyHelosAlive_MissionNotFailed,
    Test_OneFriendlyHeloStillAlive_MissionNotFailed,
    Test_AllFriendlyHelosDead_MissionFailed,
    Test_OnSamsDestroyed_HelosProceedFlagSet,
    Test_FriendlyHelosLanded_C4Explodes,
    Test_C4Exploded_EnemyAAAActivates,
    Test_EnemyAAADead_FriendlyHelosBeginEscape,
    Test_FriendlyHelosEscapedAndPlayersRTB_MissionAccomplished
  }
end

--testOnly = Test_Mission05
