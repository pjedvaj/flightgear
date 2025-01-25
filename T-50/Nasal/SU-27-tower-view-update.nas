# Tower view listener
#--------------------------------------------------------------------
# Let FG get initialised before trying to set a position.
initialise = func {
  settimer(initialise_updater, 5);
}
#--------------------------------------------------------------------
initialise_updater = func {
  setlistener("/autopilot/route-manager/wp/id", update_tower_view);
}
#--------------------------------------------------------------------
update_tower_view = func {
  next_tower_id = getprop("/autopilot/route-manager/wp/id");
  current_tower_id = getprop("/sim/tower/airport-id");
  if(next_tower_id != current_tower_id) {
    print(next_tower_id);
    settimer(switch_tower_view, 30);
  }
}
#--------------------------------------------------------------------
switch_tower_view = func {
  next_tower_id = getprop("/autopilot/route-manager/wp/id");
  setprop("/sim/tower/airport-id", next_tower_id);
}
#--------------------------------------------------------------------
