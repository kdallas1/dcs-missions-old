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

function MockMoose:Mock(className, fields)
  local mock = {
    ClassName =  className,
    New = function() end
  }
  if fields then
    for k, v in pairs(fields) do
      mock[k] = v
    end
  end
  return mock
end

function MockMoose:MockUnit(name, life)
  local unit = {
    ClassName = self.unit.ClassName,

    name = name,
    life = life,

    GetName = function(self) return self.name end,
    GetLife = function(self) return self.life end,
    GetVelocityKNOTS = function() return 0 end,
    GetVec3 = function() end,
    IsAlive = function() return true end,
  }
  self.data.units[name] = unit
  return unit
end

function MockMoose:MockGroup(name, units)
  local group = {
    ClassName = self.group.ClassName,

    name = name,
    units = units,
    aliveCount = 0,

    GetName = function(self) return self.name end,
    GetUnits = function(self) return self.units end,
    CountAliveUnits = function(self) return self.aliveCount end,
  }
  self.data.groups[name] = group
  return group
end

function MockMoose:MockZone(name)
  local zone = {
    ClassName = self.zone.ClassName,

    name = name,

    GetName = function(self) return self.name end,
    IsVec3InZone = function() end
  }
  self.data.zones[name] = zone
  return zone
end

MockMoose = createClass(Moose, MockMoose)
