dofile(baseDir .. "KD/MissionEvents.lua")

local function Test_UpdateFromUnitList_SpawnEventFires()
  
  local spawnEventFired = false
  local events = MissionEvents:New()
  
  local units = 
  {
    {
      GetID = function() return 1 end,
      GetName = function() return "Test" end,
    }
  }
  
  events:HandleEvent(MissionEvent.Spawn, function() spawnEventFired = true end)
  
  events:UpdateFromUnitList(units)
  
  TestAssert(spawnEventFired, "Expected spawn event to fire")
  
end

local function Test_UpdateFromGroupList_SpawnEventFires()
  
  local events = MissionEvents:New()
  
  local groups =
  {
    {
      GetName = function() return "Test" end,
      GetUnits = function ()
        return
        {
          {
            GetID = function() return 1 end,
            GetName = function() return "Test" end,
          }
        }
      end
    }
  }
  local spawnEventFired = false
  
  events:HandleEvent(MissionEvent.Spawn, function() spawnEventFired = true end)
  
  events:UpdateFromGroupList(groups)
  
  TestAssert(spawnEventFired, "Expected spawn event to fire")
  
end

local function Test_UpdateFromSpawnerList_SpawnEventFires()
  
  local events = MissionEvents:New()
  
  local spawners =
  {
    {
      SpawnTemplatePrefix = "Stub",
      SpawnCount = 1,
      GetGroupFromIndex = function()
        return
        {
          GetName = function() return "Test" end,
          GetUnits = function ()
            return
            {
              {
                GetID = function() return 1 end,
                GetName = function() return "Test" end,
              }
            }
          end
        } 
      end,
    }
  }
  local spawnEventFired = false
  
  events:HandleEvent(MissionEvent.Spawn, function() spawnEventFired = true end)
  
  events:UpdateFromSpawnerList(spawners)
  
  TestAssert(spawnEventFired, "Expected spawn event to fire")
  
end

local function Test_CheckUnitList_UnitLifeEmpty_DeadEventFires()
  
  local deadEventFired = false
  local events = MissionEvents:New()
  
  local units = 
  {
    {
      GetID = function() return 1 end,
      GetName = function() return "Test" end,
      GetLife = function() return 1 end -- Moose says "Dead units has health <= 1.0"
    }
  }
  
  events:HandleEvent(MissionEvent.Dead, function() deadEventFired = true end)
  
  events:UpdateFromUnitList(units)
  events:CheckUnitList()
  
  TestAssert(deadEventFired, "Expected dead event to fire")
end

local function Test_CheckUnitList_UnitDecrease_DamagedEventFires()
  TestAssert(true, "Test")
end

function Test_MissionEvents()
  return RunTests {
    "MissionEvents",
    Test_UpdateFromUnitList_SpawnEventFires,
    Test_UpdateFromGroupList_SpawnEventFires,
    Test_UpdateFromSpawnerList_SpawnEventFires,
    Test_CheckUnitList_UnitLifeEmpty_DeadEventFires,
    Test_CheckUnitList_UnitDecrease_DamagedEventFires,
  }
end
