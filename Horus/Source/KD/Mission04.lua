dofile(baseDir .. "KD/Mission.lua")

---
-- @module KD.Mission04

--- 
-- @type Mission04
-- @extends KD.Mission#Mission
Mission04 = {
  className = "Mission04",

  traceOn = true,
  traceLevel = 1,
  assert = true,
  mooseTrace = false,
  
  --- @field #Wrapper.Group#GROUP playerGroup
  playerGroup = nil,
  
  --- @field #Wrapper.Group#GROUP friendlyHeloGroup
  friendlyHeloGroup = nil,
  
  --- @field #Wrapper.Group#GROUP enemyHeloGroup
  enemyHeloGroup = nil,
  
  --- @field #Wrapper.Zone#ZONE extractionLandZone 
  extractionLandZone = nil
}

Mission04 = createClass(Mission04, Mission)

---
-- @param #Mission04 self
function Mission04:Mission04()
  
  if self.mooseTrace then  
    BASE:TraceOnOff(true)
    BASE:TraceAll(true)
    BASE:TraceLevel(3)
  end
  
  self:SetTraceOn(self.traceOn)
  self:SetTraceLevel(self.traceLevel)
  self:SetAssert(self.assert)
  
  self.playerGroup = GROUP:FindByName("Dodge Squadron")
  self.friendlyHeloGroup = GROUP:FindByName("Friendly Helos")
  self.enemyHeloGroup = GROUP:FindByName("Enemy Helos")
  self.extractionLandZone = ZONE:New("Extraction Land")
  
  self:Assert(self.playerGroup, "Player group not found")
  self:Assert(self.friendlyHeloGroup, "Friendly helo group not found")
  self:Assert(self.enemyHeloGroup, "Enemy helo group not found")
end

---
-- @param #Mission04 self
function Mission04:Start()

  self:Trace(1, "Starting mission")
  
  -- TODO: delay as this only lasts for a short period
  --self.extractionLandZone:SmokeZone(SMOKECOLOR.Red)
  
  -- TODO: trigger activate when players come close
  self.friendlyHeloGroup:Activate(0)
  
  -- TODO: trigger when friendly helo lands
  --self.enemyHeloGroup:Activate(0)
  
  SCHEDULER:New(nil,
    function() self:GameLoop() end, 
    {}, 0, self.gameLoopInterval)
  
  self:PlaySound(Sound.MissionLoaded)
  
  MESSAGE:New("Mission 4: Assist rescue of downed recon pilots", self.messageTimeShort):ToAll()
  MESSAGE:New("Read the mission brief before takeoff", self.messageTimeShort):ToAll()
  
  self:Trace(1, "Mission started")
  
end

---
-- @param #Mission04 self
function Mission04:GameLoop()
  
end
