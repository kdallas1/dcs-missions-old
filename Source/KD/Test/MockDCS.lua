---
-- @module KD.Test.MockDCS

--- 
-- @type MockDCS
-- @extends KD.DCS#DCS
MockDCS = {
  className = "MockDCS"
}

---
-- @param self #MockDCS
function MockDCS:MockDCS()
  self:SetTraceOn(false)
  self.unit = { 
    ClassName = "MockUnit",
    getByName = function() end
  }
  self.coalition = {
    side = {
      BLUE = 0
    }
  }
  self.trigger = {
    action = {
      setUserFlag = function() end
    }
  }
end

MockDCS = createClass(Moose, MockDCS)
