--- Random experimental snippet sandbox

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

local delay = 30 -- seconds

local debug = Group.getByName("Debug")
if debug ~= nil then 
  trigger.action.outTextForGroup(
    debug.getID(debug),
    "Debug: Delay " .. delay .. "s", 1000)
 end

function SwitchWaypoint(time)

  local name = 'Terrorists'
  local from = 0
  local to = 3

  local gp = Group.getByName('Terrorists')
  if gp:getSize() > 0 then

    local switchWP = { 
      id = 'SwitchWaypoint', 
      params = { 
        fromWaypointIndex = from,
        goToWaypointIndex = to + 1, -- always add 1 (different index)
      }
    }

    gp:getController():setCommand(switchWP)

    local debug = Group.getByName("Debug")
    if debug ~= nil then 
      trigger.action.outTextForGroup(
        debug.getID(debug),
        "Debug: Switch waypoint for " .. name .. " " .. from .. "->" .. to, 1000)
     end

  end

end

--timer.scheduleFunction(SwitchWaypoint, {}, timer.getTime() + delay)
