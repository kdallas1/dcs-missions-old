baseDir = [[C:\Projects\kdallas1\dcs-missions\Source\]]

dofile(baseDir .. "KD/Test/Test.lua")
if (Test()) then

  dofile(baseDir .. "../Horus/Source/Mission03.lua")
  Mission03:New():Start()
  
end
