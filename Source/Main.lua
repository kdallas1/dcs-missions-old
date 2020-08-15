env = {
  error = function(s) error(s) end,
  info = function(s) print(s) end
}

-- TODO: get current path
baseDir = [[C:\Projects\kdallas1\dcs-missions\Source\]]

dofile(baseDir .. "KD/Test/Test.lua")
Test()
