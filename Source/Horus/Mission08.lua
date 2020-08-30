dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission08

--- 
-- @type Mission08
-- @extends KD.Mission#Mission
Mission08 = {
  className = "Mission08",

  traceLevel = 2,

  launcherSiteMax = 4,
  launcherSiteUnitMinLife = 2,
  
  enemyJetPerPlayer = 2,
  enemyJetAliveCount = 0,
  enemyJetSpawnStart = 60,
  enemyJetSpawnInterval = 300
}

---
-- @type Mission08.State
-- @extends KD.Mission#MissionState
Mission08.State = {
  EnemySamsDestroyed = State:NextState(),
  EnemyCommandDestroyed = State:NextState(),
}

---
-- @param #Mission08 self
function Mission08:Mission08()

  --self:SetTraceLevel(3)
  --self.playerTestOn = false

  self.state:AddStates(Mission08.State)
  
  self.nalchikParkZone = self.moose.zone:New("Nalchik Park")
  self:Assert(self.nalchikParkZone, "Nalchik park zone not found")
  
  self.enemyCommand = self.moose.group:FindByName("Enemy Command")
  self:Assert(self.enemyCommand, "Enemy Command not found")
  self.enemyCommand.enemyCommand = true
  self:AddGroup(self.enemyCommand)
  
  self.enemySams = self.moose.group:FindByName("Enemy SAMs")
  self:Assert(self.enemySams, "Enemy SAMs not found")
  self.enemySams.enemySam = true
  self:AddGroup(self.enemySams)
  
  local sams = self.enemySams:GetUnits()
  for i = 1, #sams do
    sams[i].simpleName = "SAM " .. i
  end

  self.launcherSiteList = {}
  for i = 1, self.launcherSiteMax do
    self.launcherSiteList[#self.launcherSiteList + 1] = self:NewLauncherSite(i)
  end
  
  self.enemyJetSpawn = self.moose.spawn:New("Enemy Jets")

  self.state:TriggerOnce(
    Mission08.State.EnemySamsDestroyed,
    function() return (self.enemySams:CountAliveUnits() == 0) end,
    function() 
      self:MessageAll(MessageLength.Long, "First objective met, now destroy the command centre")
      self:PlaySound(Sound.FirstObjectiveMet)
    end
  )

  self.state:TriggerOnceAfter(
    Mission08.State.EnemyCommandDestroyed,
    Mission08.State.EnemySamsDestroyed,
    function() return (self.enemyCommand:CountAliveUnits() == 0) end,
    function()
      self:MessageAll(MessageLength.Long, "Second objective met, RTB (Nalchik WP0)")
      self:LandTestPlayers(self.playerGroup, self.moose.airbase.Caucasus.Nalchik, 400)
      self:PlaySound(Sound.SecondObjectiveMet)
    end
  )

  self.state:TriggerOnceAfter(
    MissionState.MissionAccomplished,
    Mission08.State.EnemyCommandDestroyed,
    function() return self:UnitsAreParked(self.nalchikParkZone, self.players) end
  )

  self.state:TriggerOnce(
    MissionState.MissionFailed,
    function() return (self:CountAliveLaunchers() == 0) end
  )
  
  self:SetupMenu()

end

---
-- @param #Mission08 self
function Mission08:SetupMenu()

  local menu = self.moose.menu.coalition:New(self.dcs.coalition.side.BLUE, "Debug")
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill players", menu,
    function() self:SelfDestructGroup(self.playerGroup, 100, 1, 1) end)
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill enemy SAMs", menu,
    function() self:SelfDestructGroup(self.enemySams, 100, 1, 1) end)
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill enemy Command", menu,
    function() self:SelfDestructGroup(self.enemyCommand, 100, 1, 1) end)
  
  self.moose.menu.coalitionCommand:New(
    self.dcs.coalition.side.BLUE, "Kill enemy MiGs", menu,
    function() self:SelfDestructGroupsInSpawn(self.enemyJetSpawn, 100, 1, 1) end)
  
  for i = 1, #self.launcherSiteList do
    self.moose.menu.coalitionCommand:New(
      self.dcs.coalition.side.BLUE, "Kill site " .. i .. " launchers", menu,
      function() self:SelfDestructGroup(self.launcherSiteList[i].launchers, 100, 1, 1) end)
  end
  
end

function Mission08:NewLauncherSite(i)

  local siteName = "Site " .. i
  local site = {}

  site.name = siteName
  site.firing = false
  site.reloading = false
  
  site.launchers = self.moose.group:FindByName(siteName .. " Launchers")
  self:Assert(site.launchers, siteName .. " Launchers not found")
  
  site.launchers.launcherSite = site

  self:AddGroup(site.launchers)
  
  -- smoke runs out after 300 seconds, so repeat every 300 seconds.
  self.moose.scheduler:New(nil, function() site.launchers:SmokeBlue() end, {}, 0, 300)

  return site

end

---
-- @param #Mission08 self
function Mission08:OnStart()

  self:MessageAll(MessageLength.Long, "Mission 8: Assist missile launcher assault on Mineralnye Vody")
  self:MessageAll(MessageLength.Long, "Read the mission brief before takeoff")

  -- keep trying targets every 10 seconds
  self.moose.scheduler:New(nil, function()
    self:EngageNextSam()
  end, {}, 10, 10)
  
  self.moose.scheduler:New(nil, function()
    self:SpawnEnemyJet()
  end, {}, self.enemyJetSpawnStart, self.enemyJetSpawnInterval)

end

function Mission08:SpawnEnemyJet()

  if self.enemyCommand:CountAliveUnits() <= 0 then
    self:Trace(2, "Skipping spawn enemy jet, command is dead")
    return
  end

  local maxEnemyJets = (#self.players * self.enemyJetPerPlayer)
  if (self.enemyJetAliveCount < maxEnemyJets) then
    
    self:Trace(1, "Spawning enemy MiG at Mineralnye Vody")
    self:MessageAll(MessageLength.Short, "Enemy MiG detected at Mineralnye Vody.")
    self:PlaySound(Sound.EnemyApproching)

    local group = self.enemyJetSpawn:SpawnAtAirbase(
      self.moose.airbase:FindByName(
        self.moose.airbase.Caucasus.Mineralnye_Vody
      )
    )
    
    self:AddGroup(group)
    
    self.enemyJetAliveCount = self.enemyJetAliveCount + 1
    
    self:Trace(1, "Enemy MiG spawned at Mineralnye Vody, alive: " .. self.enemyJetAliveCount)
    
  end
  
end

---
-- @param #Mission08 self
function Mission08:OnGameLoop()

  for i = 1, #self.launcherSiteList do
    local site = self.launcherSiteList[i]
    self:SelfDestructDamagedUnitsInList(site.launchers:GetUnits(), self.launcherSiteUnitMinLife)
  end
  
end

---
-- @param #Mission08 self
-- @param Wrapper.Unit#UNIT unit
function Mission08:OnPlayerSpawn(unit)
  
end

---
-- @param #Mission08 self
-- @param Wrapper.Unit#UNIT unit
function Mission08:OnUnitDead(unit)

  self:Trace(1, "Unit dead: " .. unit:GetName())

  local group = self:FindGroupForUnit(unit)
  
  if not group then
    self:Trace(1, "Group not found for unit: " .. unit:GetName())
  end
  
  if group then
  
    self:Trace(1, "Checking group: " .. group:GetName())
    
    if group.launcherSite then
    
      local site = group.launcherSite
      local launchersAlive = group:CountAliveUnits()
      
      if (launchersAlive == 0) then
      
        if (not site.lossAnnounced) then
          self:PlaySound(Sound.AlliedForcesHaveFallen)
          self:MessageAll(MessageLength.Long,
            "Launcher " .. site.name .. " has been defeated! Remaining sites: " .. self:CountAliveLauncherSites())
          
          -- make sure we don't announce it twice (when more than one unit in group)
          site.lossAnnounced = true
        end
        
      else
      
        self:PlaySound(Sound.UnitLost)
        self:MessageAll(MessageLength.Short,
          "Launcher at site " .. site.name .. " destroyed! Remaining at site: " .. launchersAlive)
          
      end
  
    end
    
    if group.enemyJet then
    
      self.enemyJetAliveCount = self.enemyJetAliveCount - 1
      
      self:MessageAll(MessageLength.Short, "Enemy MiG destroyed! Remaining: " .. self.enemyJetAliveCount)
      self:PlayEnemyDeadSound()
      
    end
    
    if group.enemySam then
      
      self:MessageAll(MessageLength.Short, "Enemy SAM destroyed! Remaining: " .. self.enemySams:CountAliveUnits())
      self:PlaySound(Sound.TargetDestoyed)
      self:EngageNextSam()
    
    end
    
    if group.enemyCommand then
      self:MessageAll(MessageLength.Short, "Enemy Command destroyed! Remaining: " .. self.enemyCommand:CountAliveUnits())
      self:PlaySound(Sound.StructureDestoyed)
    end
    
  end

end

function Mission08:CountAliveLaunchers()
  local totalLaunchersAlive = 0
  for i = 1, #self.launcherSiteList do
    local checkSite = self.launcherSiteList[i]
    totalLaunchersAlive = totalLaunchersAlive + checkSite.launchers:CountAliveUnits()
  end
  return totalLaunchersAlive
end

function Mission08:CountAliveLauncherSites()
  local totalSitesAlive = 0
  for i = 1, #self.launcherSiteList do
    local checkSite = self.launcherSiteList[i]
    if checkSite.launchers:CountAliveUnits() > 0 then
      totalSitesAlive = totalSitesAlive + 1
    end
  end
  return totalSitesAlive
end

---
-- @param #Mission08 self
function Mission08:EngageNextSam()
  
  self:Trace(1, "Checking if launcher can engage.")

  for i = 1, #self.launcherSiteList do
    local site = self.launcherSiteList[i]
    
    local sam = self.enemySams:GetFirstUnitAlive()
    if sam then
      
      self:EngageSam(site, sam)
      
    end
    
  end
  
end

function Mission08:EngageSam(site, sam)
  
  self:Trace(2, "[Launcher " .. site.name ..  "]" .. 
    " Status: firing=" .. Boolean:ToString(site.firing) ..
    " reloading=" .. Boolean:ToString(site.reloading))
  
  if site.firing or site.reloading then
    return
  end
  
  local radius = 50
  local fireRockets = nil
  local fireMins = 3
        
  local task = site.launchers:TaskFireAtPoint(
    sam:GetCoordinate():GetVec2(), radius, nil, self.moose.arty.WeaponType.Auto)
  
  self:SetGroupTask(site.launchers, task, 1)

  site.firing = true
  
  self:PlaySound(Sound.SelectTarget)
  self:MessageAll(MessageLength.Short, "[Launcher " .. site.name ..  "] Engaging target: " .. sam.simpleName)
  
  self.moose.scheduler:New(nil, function()

    -- firing complete
    site.firing = false
    self:ReloadSam(site, sam)
    
  end, {}, fireMins * 60)
end

function Mission08:ReloadSam(site, sam)

  local reloadMins = 10
  local maxRockets = 12
  
  site.reloading = true
  self:MessageAll(MessageLength.Short, "[Launcher " .. site.name ..  "] Reloading (T-" .. reloadMins .. " minutes)")
  
  site.scheduler = self.moose.scheduler:New(nil, function()
    
    local rockets = site.launchers:GetAmmunition()
    self:Trace(2, "Launcher site total ammo: " .. rockets)
    
    if rockets >= maxRockets then
    
      site.reloading = false
      self:MessageAll(MessageLength.Short, "[Launcher " .. site.name ..  "] Reloading complete")
      site.scheduler:Stop()
      
    elseif rockets > 0 then
    
      local percent = math.floor((rockets / maxRockets) * 100)
      self:MessageAll(MessageLength.Short, "[Launcher " .. site.name ..  "] Reloading: " .. percent .. "% done")
      
    end
    
  end, {}, 0, 60)
  
end

Mission08 = createClass(Mission, Mission08)
