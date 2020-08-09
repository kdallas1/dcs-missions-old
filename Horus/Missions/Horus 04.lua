baseDir = [[C:\Projects\kdallas1\dcs-missions\Horus\Source\]]

dofile(baseDir .. "KD/Test/Test.lua")
if (Test()) then

  dofile(baseDir .. "KD/Mission04.lua")
  Mission04:New():Start()
  
end
