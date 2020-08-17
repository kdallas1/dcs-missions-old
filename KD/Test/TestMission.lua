skipMoose = true
dofile(baseDir .. "KD/Mission.lua")
skipMoose = false

dofile(baseDir .. "KD/Test/MockMoose.lua")

---
-- @module KD.Test.MockMission

--- 
-- @type MockMission
-- @extends KD.Mission#Mission
local MockMission = {
  className = "MockMission"
}

---
-- @param #self #MockMission
function MockMission:MockMission()
  self:SetTraceOn(false)
  self.moose = MockMoose:New()
end

MockMission = createClass(Mission, MockMission)

local function Test_UnitsAreParked_AllVehiclesStopped_ReturnsTrue()

  local mission = MockMission:New()
  
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

  local mission = MockMission:New()
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

  local mission = MockMission:New()
  
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
  local mission = MockMission:New()
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
  local mission = MockMission:New()
  
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
  local mission = MockMission:New()
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
  local mission = MockMission:New()
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
  local explodeCallCount = 0
  local mission = MockMission:New()
  
  local units = {
    {
      GetName = function() return "Test" end,
      GetLife = function() return 1 end,
      IsAlive = function() return true end,
      Explode = function() explodeCallCount = explodeCallCount + 1 end
    }
  }
  
  local spawn = {
    ClassName = mission.moose.spawn.ClassName,
    SpawnCount = 1,
    GetGroupFromIndex = function()
      return
      {
        ClassName = mission.moose.group.ClassName,
        GetName = function() return "Test" end,
        GetUnits = function() return units end,
      }
    end,
  }
  
  mission:SelfDestructDamagedUnits(spawn, 10)
  mission:SelfDestructDamagedUnits(spawn, 10)
  
  TestAssert(explodeCallCount == 1, "Unit should self destruct when damaged")
end

local function Test_SelfDestructDamagedUnits_UndamagedUnits_DoNotSelfDestruct()
  local selfDestructCalled = false
  local mission = MockMission:New()
  
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
            {
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

local function Test_GetAliveUnitsFromSpawn_AliveUnits_CountIsCorrect()
  
  local mission = MockMission:New()
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
  local result = mission:GetAliveUnitsFromSpawn(spawn)
  
  TestAssert(result == 2, "Alive unit count should be 2, but was " .. result)
end

local function Test_FindUnitsByPrefix_InMoose_NotAddedToMooseDatabase()
  
  local addedToMooseDatabase = false
  local mission = MockMission:New()
  
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
  local mission = MockMission:New()
  
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
  local mission = MockMission:New()
  function mission:OnStart()
    onStartCalled = true
  end
  
  function mission.moose.scheduler:New() end
  function mission.moose.userSound:New() end
  function mission.moose.unit:FindByName() end
  
  mission:Start()
  
  TestAssert(onStartCalled, "Expected OnStart to be called")
  
end

local function Test_GameLoop_OnGameLoop()
  
  local onGameLoopCalled = false
  local mission = MockMission:New()
  function mission:OnGameLoop()
    onGameLoopCalled = true
  end
  
  function mission:FindUnitsByPrefix() return {} end
  
  mission:GameLoop()
  
  TestAssert(onGameLoopCalled, "Expected OnGameLoop to be called")
  
end

local function Test_MessageAllLong_MessageSent()
  local mission = MockMission:New()
  
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
  local mission = MockMission:New()
  
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
    Test_UnitsAreParked_AllVehiclesStopped_ReturnsTrue,
    Test_UnitsAreParked_SomeVehiclesMoving_ReturnsFalse,
    Test_UnitsAreParked_SomeNotInZone_ReturnsFalse,
    Test_SpawnGroupsAreParked_AllGroupsParked_ReturnsTrue,
    Test_SpawnGroupsAreParked_SomeGroupsParked_ReturnsFalse,
    Test_KeepAliveSpawnGroupsIfParked_GroupIsParked_RespawnedAtAirbase,
    Test_KeepAliveSpawnGroupsIfParked_GroupNotParked_NotRespawned,
    Test_SelfDestructDamagedUnits_DamagedUnits_SelfDestructOnce,
    Test_SelfDestructDamagedUnits_UndamagedUnits_DoNotSelfDestruct,
    Test_GetAliveUnitsFromSpawn_AliveUnits_CountIsCorrect,
    Test_FindUnitsByPrefix_InMoose_NotAddedToMooseDatabase,
    Test_FindUnitsByPrefix_NotInMooseButInDcs_AddedToMooseDatabase,
    Test_Start_OnStartCalled,
    Test_GameLoop_OnGameLoop,
    Test_MessageAllLong_MessageSent,
    Test_MessageAllShort_MessageSent
  }
end
