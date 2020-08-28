skipMoose = true
dofile(baseDir .. "KD/Mission.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")
dofile(baseDir .. "KD/Test/MockDCS.lua")

local function NewMock(fields)

  local mock = {}

  mock.moose = MockMoose:New(fields)
  mock.dcs = MockDCS:New(fields)

  local args = {
    trace = { _traceOn = false },
    moose = mock.moose,
    dcs = mock.dcs
  }

  Table:Concat(args, fields)

  mock.mission = Mission:New(args)

  return mock

end

local function NewMockMission(fields)
  return NewMock(fields).mission
end

local function Test_PlayerIsDead_StateIsMissionFailed()

  local mock = NewMock({
    --trace = { _traceOn = true, _traceLevel = 4 },
  })

  local player = mock.moose:MockUnit({
    name = "Dodge #001"
  })

  mock.moose:MockGroup({
    name = "Dodge Squadron",
    units = { player }
  })

  local announceLoseCalled = false
  local loseFunction = mock.mission.AnnounceLose
  mock.mission.AnnounceLose = function(self)
    loseFunction(self)
    announceLoseCalled = true
  end

  player.life = 40
  player.alive = true

  mock.mission:Start()

  player.life = 1
  player.alive = false

  mock.mission:GameLoop()

  TestAssert(
    mock.mission.state.current == MissionState.MissionFailed,
    "When player dead, mission state should be: Mission failed"
  )

  TestAssert(announceLoseCalled, "AnnounceLose should be called on fail")

end

local function Test_UnitsAreParked_AllVehiclesStopped_ReturnsTrue()

  local mission = NewMockMission()
  
  local zone = {
    ClassName = mission.moose.zone.ClassName,
    GetName = function() return "Test" end,
    IsVec3InZone = function() return true end
  }
  local units = {
    {
      GetName = function() return "Test" end,
      GetVelocityKNOTS = function() return 0.9 end,
      GetVec3 = function() end,
    }
  }
  
  local result = mission:UnitsAreParked(zone, units)
  TestAssert(result, "Result should be true when all units parked")
  
end

local function Test_UnitsAreParked_SomeVehiclesMoving_ReturnsFalse()

  local mission = NewMockMission()
  local zone = {
    ClassName = mission.moose.zone.ClassName,
    GetName = function() return "Test" end,
    IsVec3InZone = function() return true end
  }
  local units = {
    {
      GetName = function() return "Test" end,
      GetVelocityKNOTS = function() return 0.9 end,
      GetVec3 = function() end,
    },
    {
      GetName = function() return "Test" end,
      GetVelocityKNOTS = function() return 1 end,
      GetVec3 = function() end,
    }
  }
  
  local result = mission:UnitsAreParked(zone, units)
  TestAssert(not result, "Result should be false when some units moving")
  
end

local function Test_UnitsAreParked_SomeNotInZone_ReturnsFalse()

  local mission = NewMockMission()
  
  local callCount = 0
  
  local zone = {
    ClassName = mission.moose.zone.ClassName,
    GetName = function() return "Test" end,
    IsVec3InZone = function()
      callCount = callCount + 1
      
      -- on the 2nd call, return false
      return callCount ~= 2
    end
  }
  local units = {
    {
      GetName = function() return "Test" end,
      GetVelocityKNOTS = function() return 0 end,
      GetVec3 = function() end,
    },
    {
      GetName = function() return "Test" end,
      GetVelocityKNOTS = function() return 0 end,
      GetVec3 = function() end,
    }
  }
  
  local result = mission:UnitsAreParked(zone, units)
  TestAssert(not result, "Result should be false when some units not in zone")
  
end

local function Test_SpawnGroupsAreParked_AllGroupsParked_ReturnsTrue()
  local mission = NewMockMission()
  function mission:UnitsAreParked() return true end
  
  local zone = {
    ClassName = mission.moose.zone.ClassName,
    GetName = function() return "Test" end,
  }
  local spawn = {
    ClassName = mission.moose.spawn.ClassName,
    SpawnCount = 1,
    GetGroupFromIndex = function()
      return
      {
        ClassName = mission.moose.group.ClassName,
        GetName = function() return "Test" end,
        GetUnits = function()
          return
          {
            {} -- empty unit, not needed
          }
        end
      }
    end,
  }
  local result = mission:SpawnGroupsAreParked(zone, spawn)
  TestAssert(result, "Result should be true when all groups are parked")
end

local function Test_SpawnGroupsAreParked_SomeGroupsParked_ReturnsFalse()
  local mission = NewMockMission()
  
  local callCount = 0
  function mission:UnitsAreParked()
    callCount = callCount + 1
    
    -- on the 2nd call, return false
    return callCount ~= 2
  end
  
  local zone = {
    ClassName = mission.moose.zone.ClassName,
    GetName = function() return "Test" end,
  }
  local spawn = {
    ClassName = mission.moose.spawn.ClassName,
    SpawnCount = 2,
    GetGroupFromIndex = function()
      return
      {
        ClassName = mission.moose.group.ClassName,
        GetName = function() return "Test" end,
        GetUnits = function()
          return
          {
            {} -- empty unit, not needed
          }
        end
      }
    end,
  }
  local result = mission:SpawnGroupsAreParked(zone, spawn)
  TestAssert(not result, "Result should be false when only some groups are parked")
end

local function Test_KeepAliveSpawnGroupsIfParked_GroupIsParked_RespawnedAtAirbase()
  local respawnCalled = false
  local mission = NewMockMission()
  function mission:UnitsAreParked() return true end
  
  local zone = {
    ClassName = mission.moose.zone.ClassName,
    GetName = function() return "Test" end,
  }
  local spawn = {
    ClassName = mission.moose.spawn.ClassName,
    SpawnCount = 1,
    GetGroupFromIndex = function()
      return
      {
        ClassName = mission.moose.group.ClassName,
        GetName = function() return "Test" end,
        GetUnits = function()
          return
          {
            {} -- empty unit, not needed
          }
        end,
        RespawnAtCurrentAirbase = function()
          respawnCalled = true 
        end
      }
    end,
  }
  
  mission:KeepAliveSpawnGroupsIfParked(zone, spawn)
  
  TestAssert(respawnCalled, "Group should be respawned when parked")
end

local function Test_KeepAliveSpawnGroupsIfParked_GroupNotParked_NotRespawned()
  local respawnCalled = false
  local mission = NewMockMission()
  function mission:UnitsAreParked() return false end
  
  local zone = {
    ClassName = mission.moose.zone.ClassName,
    GetName = function() return "Test" end,
  }
  local spawn = {
    ClassName = mission.moose.spawn.ClassName,
    SpawnCount = 1,
    GetGroupFromIndex = function()
      return
      {
        ClassName = mission.moose.group.ClassName,
        GetName = function() return "Test" end,
        GetUnits = function()
          return
          {
            {} -- empty unit, not needed
          }
        end,
        RespawnAtCurrentAirbase = function()
          respawnCalled = true 
        end
      }
    end,
  }
  
  mission:KeepAliveSpawnGroupsIfParked(zone, spawn)
  
  TestAssert(not respawnCalled, "Group should not be respawned when not parked")
end

local function Test_SelfDestructDamagedUnits_DamagedUnits_SelfDestructOnce()
  
  local mock = NewMock(fields)
  local mission = mock.mission
  
  local explodeCallCount = 0
  local unit = mock.moose:MockUnit {
    GetName = function() return "Test" end,
    GetLife = function() return 1 end,
    IsAlive = function() return true end,
    Explode = function() explodeCallCount = explodeCallCount + 1 end
  }
  
  local spawn = mock.moose:MockSpawn {
    SpawnCount = 1,
    GetGroupFromIndex = function()
      return
      mock.moose:MockGroup {
        GetName = function() return "Test" end,
        GetUnits = function() return { unit } end,
      }
    end,
  }
  
  mission:SelfDestructDamagedUnits(spawn, 10)
  mission:SelfDestructDamagedUnits(spawn, 10)
  
  TestAssert(explodeCallCount == 1, "Unit should self destruct 1 time when damaged, actual: " .. explodeCallCount)
end

local function Test_SelfDestructDamagedUnits_UndamagedUnits_DoNotSelfDestruct()
  
  local mock = NewMock(fields)
  local mission = mock.mission
  
  local selfDestructCalled = false
  local spawn = mock.moose:MockSpawn {
    SpawnCount = 1,
    GetGroupFromIndex = function()
      return
      mock.moose:MockGroup {
        GetName = function() return "Test" end,
        GetUnits = function()
          return
          {
            mock.moose:MockUnit {
              GetName = function() return "Test" end,
              GetLife = function() return 11 end,
              IsAlive = function() return true end,
              Explode = function() selfDestructCalled = true end
            }
          }
        end,
      }
    end,
  }
  
  mission:SelfDestructDamagedUnits(spawn, 10)
  
  TestAssert(not selfDestructCalled, "Unit should not self destruct when undamaged")
end

local function Test_CountAliveUnitsFromSpawn_AliveUnits_CountIsCorrect()
  
  local mock = NewMock()
  local spawn = mock.moose:MockSpawn {
    SpawnCount = 1,
    GetGroupFromIndex = function()
      return mock.moose:MockGroup {
        GetName = function() return "Test" end,
        GetUnits = function()
          return
          {
            {
              GetName = function() return "Test" end,
              IsAlive = function() return true end
            },
            {
              GetName = function() return "Test" end,
              IsAlive = function() return false end
            },
            {
              GetName = function() return "Test" end,
              IsAlive = function() return true end
            },
          }
        end,
      }
    end,
  }
  local result = mock.mission:CountAliveUnitsFromSpawn(spawn)
  
  TestAssert(result == 2, "Alive unit count should be 2, but was " .. result)
end

local function Test_FindUnitsByPrefix_InMoose_NotAddedToMooseDatabase()
  
  local addedToMooseDatabase = false
  local mission = NewMockMission()
  
  mission.moose.unit = {
    FindByName = function(self, name)
      if name == "Test #001" then
        return
        {
          GetName = function() return "Test" end
        }
      end
    end
  }
  mission.dcs.unit = {
    getByName = function()
      return {}
    end
  }
  mission.moose.database = {
    AddUnit = function(self, unit)
      addedToMooseDatabase = true
    end
  }
  
  mission:FindUnitsByPrefix("Test", 1)
  
  TestAssert(not addedToMooseDatabase, "Expected DCS unit not to be added Moose database")
end

local function Test_FindUnitsByPrefix_NotInMooseButInDcs_AddedToMooseDatabase()
  
  local addedToMooseDatabase = false
  local mission = NewMockMission()
  
  mission.moose.unit = {
    FindByName = function() end
  }
  mission.dcs.unit = {
    getByName = function()
      return {}
    end
  }
  mission.moose.database = {
    AddUnit = function(self, unit)
      addedToMooseDatabase = (unit == "Test #001")
    end
  }
  
  mission:FindUnitsByPrefix("Test", 1)
  
  TestAssert(addedToMooseDatabase, "Expected DCS unit to be added Moose database")
end

local function Test_Start_OnStartCalled()
  
  local onStartCalled = false
  local mission = NewMockMission()
  function mission:OnStart()
    onStartCalled = true
  end
  
  function mission:FindUnitsByPrefix() return {} end
  
  mission:Start()
  
  TestAssert(onStartCalled, "Expected OnStart to be called")
  
end

local function Test_GameLoop_OnGameLoop()
  
  local onGameLoopCalled = false
  local mission = NewMockMission()
  function mission:OnGameLoop()
    onGameLoopCalled = true
  end
  
  function mission:FindUnitsByPrefix() return {} end
  
  mission:GameLoop()
  
  TestAssert(onGameLoopCalled, "Expected OnGameLoop to be called")
  
end

local function Test_MessageAllLong_MessageSent()
  local mission = NewMockMission()
  
  local sent = false
  function mission.moose.message:New()
    return {
      ToAll = function() sent = true end
    }
  end
  
  mission:MessageAll(MessageLength.Long, "Test")
  
  TestAssert(sent, "Expected long message to send")
end

local function Test_MessageAllShort_MessageSent()
  local mission = NewMockMission()
  
  local sent = false
  function mission.moose.message:New()
    return {
      ToAll = function() sent = true end
    }
  end
  
  mission:MessageAll(MessageLength.Short, "Test")
  
  TestAssert(sent, "Expected short message to send")
end

function Test_Mission()
  return RunTests {
    "Mission",
    Test_PlayerIsDead_StateIsMissionFailed,
    Test_UnitsAreParked_AllVehiclesStopped_ReturnsTrue,
    Test_UnitsAreParked_SomeVehiclesMoving_ReturnsFalse,
    Test_UnitsAreParked_SomeNotInZone_ReturnsFalse,
    Test_SpawnGroupsAreParked_AllGroupsParked_ReturnsTrue,
    Test_SpawnGroupsAreParked_SomeGroupsParked_ReturnsFalse,
    Test_KeepAliveSpawnGroupsIfParked_GroupIsParked_RespawnedAtAirbase,
    Test_KeepAliveSpawnGroupsIfParked_GroupNotParked_NotRespawned,
    Test_SelfDestructDamagedUnits_DamagedUnits_SelfDestructOnce,
    Test_SelfDestructDamagedUnits_UndamagedUnits_DoNotSelfDestruct,
    Test_CountAliveUnitsFromSpawn_AliveUnits_CountIsCorrect,
    Test_FindUnitsByPrefix_InMoose_NotAddedToMooseDatabase,
    Test_FindUnitsByPrefix_NotInMooseButInDcs_AddedToMooseDatabase,
    Test_Start_OnStartCalled,
    Test_GameLoop_OnGameLoop,
    Test_MessageAllLong_MessageSent,
    Test_MessageAllShort_MessageSent
  }
end
