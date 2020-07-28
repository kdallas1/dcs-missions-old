-- testing trigger on waypoint
function helloWaypoint(unit, waypoints)
  hlog("Hello waypoint: " .. unit:GetName())
  unit:Route(waypoints)
end

-- trying to patrol between two waypoints
function patrol()
  local recon = GROUP:FindByName("Recon")
  local waypoints = recon:GetTaskRoute()
  local waypoint = waypoints[#waypoints]
  local task = recon:TaskFunction("helloWaypoint", recon)
  recon:SetTaskWaypoint(waypoint, task, waypoints)
  recon:Route(waypoints)
end
