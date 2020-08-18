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
end

MockDCS = createClass(Moose, MockDCS)
