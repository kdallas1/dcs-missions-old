dofile(baseDir .. "KD/KDObject.lua")

---
-- @module KD.DCS

--- 
-- @type DCS
-- @extends KD.KDObject#KDObject
DCS = {
  className = "DCS"
}

---
-- @function [parent=#DCS] New
-- @param #DCS self
-- @return #DCS

---
-- @param #DCS self
function DCS:DCS()
  self.unit = Unit
  self.coalition = coalition
  self.trigger = trigger
end

DCS = createClass(KDObject, DCS)
