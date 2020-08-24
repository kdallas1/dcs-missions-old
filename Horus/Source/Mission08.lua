dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission08

--- 
-- @type Mission08
-- @extends KD.Mission#Mission
Mission08 = {
  className = "Mission08",

  traceLevel = 2,

  launcherSiteMax = 4
}

---
-- @type Mission08.State
-- @extends KD.Mission#MissionState
Mission08.State = {
}

---
-- @param #Mission08 self
function Mission08:Mission08()

  self.nalchikParkZone = self.moose.zone:New("Nalchik Park")
  self:Assert(self.nalchikParkZone, "Nalchik park zone not found")

  self.launcherSiteList = {}
  for i = 1, self.launcherSiteMax do
    self.launcherSiteList[#self.launcherSiteList + 1] = self:NewLauncherSite(i)
  end

end

function Mission08:NewLauncherSite(i)

  local siteName = "Site " .. i
  local site = {}

  site.name = siteName
  site.launchers = self.moose.group:FindByName(siteName .. " Launchers")
  site.tanks = self.moose.group:FindByName(siteName .. " Tanks")

  self:Assert(site.launchers, siteName .. " Launchers not found")
  self:Assert(site.tanks, siteName .. " Tanks not found")

  site.launchers.launcherSite = site
  site.tanks.launcherSite = site

  self:AddGroup(site.launchers)
  self:AddGroup(site.tanks)

  return site

end

---
-- @param #Mission08 self
function Mission08:OnStart()

  self:MessageAll(MessageLength.Long, "Mission 8: Assist missile launcher assault on Mineralnye Vody")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")

end

---
-- @param #Mission08 self
function Mission08:OnGameLoop()
end

---
-- @param #Mission08 self
-- @param Wrapper.Unit#UNIT unit
function Mission08:OnUnitDamaged(unit)

  self:Trace(1, "Unit damaged: " .. unit:GetName())

  local group = unit:GetGroup()

  if (group and group.launcherSite) then

    self:PlaySound(Sound.OurBaseIsUnderAttack)
    self:MessageAll(MessageLength.Long, group.launcherSite.name .. " is under attack!")

  end

end

---
-- @param #Mission08 self
-- @param Wrapper.Unit#UNIT unit
function Mission08:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())

  local group = unit:GetGroup()

  if (group and group.launcherSite) then

    local site = group.launcherSite

    local launchersAlive = site.launchers:CountAliveUnits()

    self:PlaySound(Sound.UnitLost)
    if launchersAlive == 0 then
      self:MessageAll(MessageLength.Long, site.name .. " has been defeated!")
    end

    local totalLaunchersAlive = 0
    for i = 1, #self.launcherSiteList do
      local checkSite = self.launcherSiteList[i]
      totalLaunchersAlive = totalLaunchersAlive + checkSite.launchers:CountAliveUnits()
    end

    if totalLaunchersAlive == 0 then
      self.state:Change(MissionState.MissionFailed)
    end

  end

end

Mission08 = createClass(Mission, Mission08)
