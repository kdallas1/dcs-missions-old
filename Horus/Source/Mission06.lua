dofile(baseDir .. "KD/Mission.lua")

---
-- @module Horus.Mission06

--- 
-- @type Mission06
-- @extends KD.Mission#Mission
Mission06 = {
  className = "Mission06",

  traceLevel = 2,
}

---
-- @param #Mission06 self
function Mission06:Mission06()
end

---
-- @param #Mission06 self
function Mission06:OnStart()
end

---
-- @param #Mission06 self
function Mission06:OnGameLoop()
end

Mission06 = createClass(Mission, Mission06)
