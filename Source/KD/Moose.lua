dofile(baseDir .. "KD/KDObject.lua")

if not skipMoose then
  dofile(baseDir .. "../Moose/Moose.lua")
end

---
-- @module KD.Moose

--- 
-- @type Moose
-- @extends KD.KDObject#KDObject
Moose = {
  className = "Moose"
}

---
-- @function [parent=#Moose] New
-- @param #Moose self
-- @return #Moose

---
-- @param #Moose self
function Moose:Moose()
  self.zone = ZONE
  self.spawn = SPAWN
  self.group = GROUP
  self.unit = UNIT
  self.static = STATIC
  self.arty = ARTY
  self.scheduler = SCHEDULER
  self.userSound = USERSOUND
  self.message = MESSAGE
  self.airbase = AIRBASE
  self.menu = {
    className = "Menu",
    coalition = MENU_COALITION,
    coalitionCommand = MENU_COALITION_COMMAND
  }
end

Moose = createClass(KDObject, Moose)
