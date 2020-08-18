skipMoose = true
dofile(baseDir .. "Horus/Source/Mission05.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)
  local mock = {}

  local moose = MockMoose:New()
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

  moose:MockGroup({ name = "Enemy SAMs", aliveCount = 2 })
  moose:MockZone({ name = "Landing" })

  moose.message.New = function()
    return {
      ToAll = function() end
    }
  end

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

local function Test_FriendlyHelosAlive_MissionNotFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local mission = mock.mission

  mission:Start()
  mission:GameLoop()

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
  mission:GameLoop()

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
  mission:GameLoop()

  mock.friendlyHeloGroup.aliveCount = 0
  
  mission:GameLoop()

  TestAssert(
    mission.state.current == MissionState.MissionFailed,
    "Mission state should be failed")

end

function Test_Mission05()
  return RunTests {
    "Mission05",
    Test_FriendlyHelosAlive_MissionNotFailed,
    Test_OneFriendlyHeloStillAlive_MissionNotFailed,
    Test_AllFriendlyHelosDead_MissionFailed
  }
end
