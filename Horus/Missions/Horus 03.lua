baseDir = [[C:\Projects\kdallas1\dcs-missions\Horus\Source\]]

dofile(baseDir .. "KD/Test/Test.lua")
if (Test()) then

  dofile(baseDir .. "KD/Mission03.lua")
  Mission03:New():Start()
  
end
