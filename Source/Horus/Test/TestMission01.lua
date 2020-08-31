skipMoose = true
dofile(baseDir .. "Horus/Mission01.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)
  
  mock.player = mock.moose:MockUnit({ name = "Dodge #001" })
  mock.playerGroup = mock.moose:MockGroup({
    name = "Dodge Squadron",
    units = { mock.player },
    IsAnyInZone = function() return false end
  })
  
  mock.moose:MockZone({ name = "Send MiGs" })
  mock.moose:MockGroup({ name = "MiGs 1A" })
  mock.moose:MockGroup({ name = "MiGs 1B" })
  mock.moose:MockGroup({ name = "MiGs 2A" })
  mock.moose:MockGroup({ name = "MiGs 2B" })
  mock.moose:MockUnit({ name = "EWR 2 SAM #001" })
  
  mock.ewr = {}
  mock.ewr[1] = mock.moose:MockUnit({ name = "EWR #001" })
  mock.ewr[2] = mock.moose:MockUnit({ name = "EWR #002" })
  mock.ewr[3] = mock.moose:MockUnit({ name = "EWR #003" })
  
  mock.dcs = MockDCS:New()

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission01:New(args)

  return mock
  
end

local function Test_Start_Default_StateIsMissionStarted()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  mock.mission:Start()

  TestAssert(
    mock.mission.state.current == MissionState.MissionStarted,
    "State should be: Mission accomplished")

end

local function Test_PlayerInMigZone_NorthMigsActivated()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })
  
  mock.playerGroup.IsAnyInZone = function(self, zone)
    if zone:GetName() == "Send MiGs" then return true end
  end
  
  local activateCalled = { false, false }
  mock.mission.migs1A.Activate = function() activateCalled[1] = true end
  mock.mission.migs1B.Activate = function() activateCalled[2] = true end

  mock.mission:Start()

  TestAssert(activateCalled[1], "Expected MiG 1A to be activated")
  TestAssert(activateCalled[2], "Expected MiG 1B to be activated")

end

local function Test_EwrDestroyed_SouthMigsActivated()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })
    
  local activateCalled = { false, false }
  mock.mission.migs2A.Activate = function() activateCalled[1] = true end
  mock.mission.migs2B.Activate = function() activateCalled[2] = true end

  mock.mission:Start()
  
  mock.mission.state.current = Mission01.State.SendNorthMigs 
  mock.ewr[1]:MockKill()
  
  mock.mission:GameLoop()

  TestAssert(activateCalled[1], "Expected 2A to be activated")
  TestAssert(activateCalled[2], "Expected 2B to be activated")

end

local function Test_AllEwrDestroyed_StateIsAllEwrDead()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })
    
  local activateCalled = { false, false }
  mock.mission.migs2A.Activate = function() activateCalled[1] = true end
  mock.mission.migs2B.Activate = function() activateCalled[2] = true end

  mock.mission:Start()
  
  mock.mission.state.current = Mission01.State.SendSouthMigs
  mock.ewr[1]:MockKill()
  mock.ewr[2]:MockKill()
  mock.ewr[3]:MockKill()
  mock.player.velocity = 20
  
  mock.mission:GameLoop()
  
  TestAssertEqual(
    Mission01.State.AllEwrDead,
    mock.mission.state.current,
    "mission state",
    function(v) return mock.mission.state:GetStateName(v) end)

end

local function Test_StateIsAllEwrDeadAndPlayersLanded_StateIsMissionAccomplished()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })
  
  mock.mission:Start()
  
  mock.mission.state.current = Mission01.State.AllEwrDead
  mock.player.IsAboveRunway = function() return true end
  
  mock.mission:GameLoop()
  
  TestAssertEqual(
    MissionState.MissionAccomplished,
    mock.mission.state.current,
    "mission state",
    function(v) return mock.mission.state:GetStateName(v) end)
  
end

testOnly = Test_EwrDestroyed_StateIsAllEwrDead

function Test_Mission01()
  return RunTests {
    "Mission01",
    Test_Start_Default_StateIsMissionStarted,
    Test_PlayerInMigZone_NorthMigsActivated,
    Test_EwrDestroyed_SouthMigsActivated,
    Test_AllEwrDestroyed_StateIsAllEwrDead,
    Test_StateIsAllEwrDeadAndPlayersLanded_StateIsMissionAccomplished
  }
end

--testOnly = Test_Mission01
