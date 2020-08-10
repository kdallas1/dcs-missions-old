dofile(baseDir .. "KD/Events.lua")

local function Test_UpdateFromUnitList_SpawnEventFires()
  
  local spawnEventFired = false
  local events = Events:New()
  
  local units = 
  {
    {
      GetID = function() return 1 end,
      GetName = function() return "Test" end,
    }
  }
  
  events:HandleEvent(Event.Spawn, function() spawnEventFired = true end)
  
  events:UpdateFromUnitList(units)
  
  TestAssert(spawnEventFired, "Expected spawn event to fire")
  
end

local function Test_UpdateFromGroupList_SpawnEventFires()
  
  local events = Events:New()
  
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
  
  events:HandleEvent(Event.Spawn, function() spawnEventFired = true end)
  
  events:UpdateFromGroupList(groups)
  
  TestAssert(spawnEventFired, "Expected spawn event to fire")
  
end

local function Test_UpdateFromSpawnerList_SpawnEventFires()
  
  local events = Events:New()
  
  local spawners =
  {
    {
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
  
  events:HandleEvent(Event.Spawn, function() spawnEventFired = true end)
  
  events:UpdateFromSpawnerList(spawners)
  
  TestAssert(spawnEventFired, "Expected spawn event to fire")
  
end

local function Test_CheckUnitList_UnitLifeEmpty_DeadEventFires()
  
  local deadEventFired = false
  local events = Events:New()
  
  local units = 
  {
    {
      GetID = function() return 1 end,
      GetName = function() return "Test" end,
      GetLife = function() return 1 end -- Moose says "Dead units has health <= 1.0"
    }
  }
  
  events:HandleEvent(Event.Dead, function() deadEventFired = true end)
  
  events:UpdateFromUnitList(units)
  events:CheckUnitList()
  
  TestAssert(deadEventFired, "Expected dead event to fire")
end

local function Test_CheckUnitList_UnitDecrease_DamagedEventFires()
  TestAssert(true, "Test")
end

function Test_Events()
  return RunTests {
    "Events",
    Test_UpdateFromUnitList_SpawnEventFires,
    Test_UpdateFromGroupList_SpawnEventFires,
    Test_UpdateFromSpawnerList_SpawnEventFires,
    Test_CheckUnitList_UnitLifeEmpty_DeadEventFires,
    Test_CheckUnitList_UnitDecrease_DamagedEventFires,
  }
end
