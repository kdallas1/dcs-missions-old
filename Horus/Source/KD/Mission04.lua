dofile(baseDir .. "KD/Mission.lua")

---
-- @module KD.Mission04

--- 
-- @type Mission04
-- @extends KD.Mission#Mission
Mission04 = {
  className = "Mission04",

  traceLevel = 3,
  
  playerGroup = nil,
  friendlyHeloGroup = nil,
  enemyHeloGroup = nil,
  extractionLandZone = nil,
  extractionZone = nil
}

---
-- @param #Mission04 self
function Mission04:Mission04()
  
  self.playerGroup = GROUP:FindByName("Dodge Squadron")
  self.friendlyHeloGroup = GROUP:FindByName("Friendly Helos")
  self.enemyHeloGroup = GROUP:FindByName("Enemy Helos")
  self.extractionLandZone = ZONE:New("Extraction Land")
  self.extractionZone = ZONE:New("Extraction")
  
  self:Assert(self.playerGroup, "Player group not found")
  self:Assert(self.friendlyHeloGroup, "Friendly helo group not found")
  self:Assert(self.enemyHeloGroup, "Enemy helo group not found")
  
  self:AddGroup(self.friendlyHeloGroup)
  self:AddGroup(self.enemyHeloGroup)
end

---
-- @param #Mission04 self
function Mission04:OnStart()
  
  -- TODO: trigger activate when players come close
  self.friendlyHeloGroup:Activate(0)
  
  MESSAGE:New("Mission 4: Assist rescue of downed recon pilots", self.messageTimeShort):ToAll()
  MESSAGE:New("Read the mission brief before takeoff", self.messageTimeShort):ToAll()
  
end

---
-- @param #Mission04 self
-- @param Wrapper.Unit#UNIT unit
function Mission04:OnUnitDead(unit)
  self:Trace(1, "Unit dead: " .. unit:GetName())
    
  if (string.match(unit:GetName(), "Friendly Helo")) then
    
    self:Trace(1, "Friendly helo destroyed: " .. unit:GetName())
    self:MessageAll(MessageLength.Long, "Friendly helo destroyed!")
    self:PlaySound(Sound.UnitLost)
    
    if (not self.winLoseDone) then
      self:AnnounceLose(2)
    end
    
  end
end

---
-- @param #Mission04 self
function Mission04:OnGameLoop()
  
  if ((not self.enemyHelosActivated) and self.friendlyHeloGroup:IsCompletelyInZone(self.extractionZone)) then
    self.enemyHeloGroup:Activate(0)
    self:PlaySound(Sound.EnemyApproching, 0)
    self:MessageAll(MessageLength.Short, "Enemy attack helos inbound from Nalchik to Fahrn, ETA 2 minutes")
    self:Trace(1, "Enemy helos activated")
    self.enemyHelosActivated = true
  end
  
  if ((not self.friendlyHelosSignalled) and self:GroupIsParked(self.extractionLandZone, self.friendlyHeloGroup)) then 
      self.friendlyHeloGroup:SmokeRed()
      self:MessageAll(MessageLength.Short, "Friendly helos landed Fahrn, extraction T-1 minute")
      self:Trace(1, "Friendly helos landed")
      self.friendlyHelosSignalled = true
  end
  
  self:SelfDestructDamagedUnitsInList(self.friendlyHeloGroup:GetUnits(), 10)
  
end

Mission04 = createClass(Mission04, Mission)
