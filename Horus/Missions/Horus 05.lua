baseDir = [[C:\Projects\kdallas1\dcs-missions\Source\]]

dofile(baseDir .. "KD/Test/Test.lua")
if (Test()) then

  dofile(baseDir .. "../Horus/Source/Mission05.lua")
  Mission05:New():Start()
  
end
