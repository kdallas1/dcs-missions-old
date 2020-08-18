dofile(baseDir .. "KD/KDObject.lua")

---
-- @module KD.DCS

--- 
-- @type DCS
DCS = {
  className = "DCS"
}

---
-- @param self #DCS
function DCS:DCS()
  self.unit = Unit
  self.coalition = coalition
end

DCS = createClass(KDObject, DCS)
