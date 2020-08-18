skipMoose = true
dofile(baseDir .. "KD/Moose.lua")
skipMoose = false

---
-- @module KD.Test.MockMoose

---
-- @type MockMoose
-- @extends KD.Moose#Moose
MockMoose = {
  className = "MockMoose"
}

---
-- @param self #MockMoose
function MockMoose:MockMoose()

  self:SetTraceOn(false)

  self.data = {
    groups = {},
    units = {},
    zones = {}
  }

  self.spawn = self:Mock("MockSpawn")
  self.group = self:Mock("MockGroup", { data = self.data })
  self.unit = self:Mock("MockUnit", { data = self.data })
  self.zone = self:Mock("MockZone", { data = self.data })
  self.scheduler = self:Mock("MockScheduler")
  self.userSound = self:Mock("MockUserSound")
  self.message = self:Mock("MockMessage")
  self.menu = self:Mock("MockMenu", {
    coalition = self:Mock("MockMenuCoalition"),
    coalitionCommand = self:Mock("MockMenuCoalitionCommand")
  })

  self.group.FindByName = function(self, name) return self.data.groups[name] end
  self.unit.FindByName = function(self, name) return self.data.units[name] end
  self.zone.FindByName = function(self, name) return self.data.zones[name] end

end

function MockMoose:Mock(className, fields1, fields2)
  local mock = {
    ClassName =  className,
    New = function() end
  }
  if fields1 then
    for k, v in pairs(fields1) do
      mock[k] = v
    end
  end
  if fields2 then
    for k, v in pairs(fields2) do
      mock[k] = v
    end
  end
  return mock
end

function MockMoose:MockUnit(fields)
  local unit = self:Mock(
    self.unit.ClassName,
    {
      name = "Mock",
      life = 0,

      GetName = function(self) return self.name end,
      GetLife = function(self) return self.life end,
      GetVelocityKNOTS = function() return 0 end,
      GetVec3 = function() end,
      IsAlive = function() return true end,
    },
    fields
  )
  self.data.units[unit.name] = unit
  return unit
end

function MockMoose:MockGroup(fields)
  local group = self:Mock(
    self.group.ClassName,
    {
      name = "Mock",
      units = {},
      aliveCount = 0,

      GetName = function(self) return self.name end,
      GetUnits = function(self) return self.units end,
      CountAliveUnits = function(self) return self.aliveCount end,
    },
    fields
  )
  self.data.groups[group.name] = group
  return group
end

function MockMoose:MockZone(fields)
  local zone = self:Mock(
    self.zone.ClassName,
    {
      name = "Mock",

      GetName = function(self) return self.name end,
      IsVec3InZone = function() end
    },
    fields
  )
  self.data.zones[zone.name] = zone
  return zone
end

MockMoose = createClass(Moose, MockMoose)
