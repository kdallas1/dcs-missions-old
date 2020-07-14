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

timer.scheduleFunction(SwitchWaypoint, {}, timer.getTime() + delay)
