dofile(baseDir .. "KD/KDObject.lua")

if not skipMoose then
  dofile(baseDir .. "Moose/Moose.lua")
end

---
-- @module KD.Moose

--- 
-- @type Moose
Moose = {
  className = "Moose"
}

---
-- @param self #Moose
function Moose:Moose()
  self.zone = ZONE
  self.spawn = SPAWN
  self.group = GROUP
  self.unit = UNIT
  self.static = STATIC
  self.scheduler = SCHEDULER
  self.userSound = USERSOUND
  self.message = MESSAGE
  self.menu = {
    className = "Menu",
    coalition = MENU_COALITION,
    coalitionCommand = MENU_COALITION_COMMAND
  }
end

Moose = createClass(KDObject, Moose)
