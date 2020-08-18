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
  self.unit = { ClassName = "MockUnit" }
  self.coalition = {
    side = {
      BLUE = 0
    }
  }
end

MockDCS = createClass(Moose, MockDCS)
