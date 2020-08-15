baseDir = [[C:\Projects\kdallas1\dcs-missions\Source\]]

dofile(baseDir .. "KD/Test/Test.lua")
if (Test()) then

  dofile(baseDir .. "../Horus/Source/Mission04.lua")
  Mission04:New():Start()
  
end
