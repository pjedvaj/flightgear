#--------------------------------------------------------------------
toggle_fcs_stick_mode = func {
  fcs_stick_mode = getprop("/autopilot/FCS/modes/stick");
  
  if(fcs_stick_mode == "FCS") {
    setprop("/autopilot/FCS/modes/stick", "direct");
  } elsif(fcs_stick_mode == "direct") {
    setprop("/autopilot/FCS/modes/stick", "FCS");
  }
}
#--------------------------------------------------------------------
toggle_auto_speedbrake = func {
  auto_speedbrake_lock = getprop("/autopilot/FCS/locks/auto-speedbrake");

  if(auto_speedbrake_lock == "engaged") {
    setprop("/autopilot/FCS/locks/auto-speedbrake", "off");
    setprop("/controls/flight/spoilers", 0);
  } else {
    setprop("/autopilot/FCS/locks/auto-speedbrake", "engaged");
  }
  # Re-set the speed lock to force the autospeedbrake listener to
  # set the appropriate auto-speedbrake mode.
  speed_lock  = getprop("/autopilot/locks/speed");
  setprop("/autopilot/locks/speed", speed_lock);
}
#--------------------------------------------------------------------
toggle_auto_flaps = func {
  fcs_auto_flaps_lock = getprop("/autopilot/FCS/locks/auto-flaps");

  if(fcs_auto_flaps_lock == "engaged") {
    setprop("/autopilot/FCS/locks/auto-flaps", "off");
  } else {
    setprop("/autopilot/FCS/locks/auto-flaps", "engaged");
  }
}
#--------------------------------------------------------------------
toggle_auto_slats = func {
  fcs_auto_slats_lock = getprop("/autopilot/FCS/locks/auto-slats");

  if(fcs_auto_slats_lock == "engaged") {
    setprop("/autopilot/FCS/locks/auto-slats", "off");
  } else {
    setprop("/autopilot/FCS/locks/auto-slats", "engaged");
  }
}
#--------------------------------------------------------------------
toggle_auto_reheat = func {
  fcs_auto_reheat_lock = getprop("/autopilot/FCS/locks/auto-reheat");

  if(fcs_auto_reheat_lock == "engaged") {
    setprop("/autopilot/FCS/locks/auto-reheat", "off");
  } else {
    setprop("/autopilot/FCS/locks/auto-reheat", "engaged");
  }
}
#--------------------------------------------------------------------
