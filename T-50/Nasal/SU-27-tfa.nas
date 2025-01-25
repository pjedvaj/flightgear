# Initialise some variables outside the functions;
  var htgt = nil;
  var dialog = gui.Dialog.new("/sim/gui/dialogs/SU-37/TFA-popup/dialog",
               "Aircraft/SU-37/Dialogs/TFA-popup.xml");
#--------------------------------------------------------------------
var collision_monitor = func {
  var alt_mode =       props.globals.getNode("/autopilot/locks/altitude", 1);
  var hi_alt_ft =      props.globals.getNode("/instrumentation/terrain-radar/hi-elev/alt-ft", 1);
  var hi_elev_dist_m = props.globals.getNode("/instrumentation/terrain-radar/hi-elev/dist-m", 1);
  var curr_gspd_kt =   props.globals.getNode("/velocities/groundspeed-kt", 1);
  var curr_vfps =      props.globals.getNode("/velocities/vertical-speed-fps", 1);
  var curr_alt_ft =    props.globals.getNode("/position/altitude-ft", 1);

  var max_climb_rate =   props.globals.getNode("/instrumentation/terrain-radar/settings/max-climb-rate-fps", 1);
  var collision_status = props.globals.getNode("/instrumentation/terrain-radar/hi-elev/collision-status", 1);

  # Convert distance from m into feet.
  var hi_elev_dist_ft = (hi_elev_dist_m.getValue() * 3.28);

  # Convert groundspeed from kts into feet per second
  var curr_gspd_fps = (curr_gspd_kt.getValue() * 1.6878092);

  var time = hi_elev_dist_ft / curr_gspd_fps;
  if(time > 2) {  # Do this to stop false positives from very close new hi-elevs
    if((time * curr_vfps.getValue()) < (hi_alt_ft.getValue() - curr_alt_ft.getValue())) {
      if((time * max_climb_rate.getValue()) < (hi_alt_ft.getValue() - curr_alt_ft.getValue())) {
        collision_status.setValue("collision");
      } else {
        collision_status.setValue("warning");
      }
    } else {
      collision_status.setValue("");
    }
  }

  # Check that agl-hold is still engaged and schedule the next loop if it is.
  if(alt_mode.getValue() == "agl-hold") {
    settimer(collision_monitor, 0.5);
  }
}
#--------------------------------------------------------------------
var tfa_radar_continuous_mode_loop = func {
  # This function checks to see if we are still approaching the high elevation
  # or whether we have passed it.
  # If we are still approaching it we leave the current high elevation alone.
  # If we have passed the current high elevation we reset the current high elevation.

  var radar_state =  props.globals.getNode("/instrumentation/terrain-radar/settings/state");
  var radar_mode =   props.globals.getNode("/instrumentation/terrain-radar/settings/mode");
  var hi_elev_alt =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/alt-ft", 1);
  var hi_elev_lat =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lat-deg", 1);
  var hi_elev_lon =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lon-deg", 1);
  var hi_elev_dist = props.globals.getNode("/instrumentation/terrain-radar/hi-elev/dist-m", 1);

  # Set up a geo container for the stored high elevation location and validate it.
  var stor_coord = geo.Coord.new().set_latlon(hi_elev_lat.getValue(), hi_elev_lon.getValue());
  if(stor_coord.is_defined()) {
    # Get the current distance to the stored high elevation location.
    var curr_dist = geo.aircraft_position().distance_to(stor_coord);
  } else {
    # We've got a bad coord stored - zero it and re-scan.
    var curr_dist = 0;
  }

  # Test to see if we are still approaching the high elevation.
  if(curr_dist < hi_elev_dist.getValue()) {
    # YES - we are still approaching the high elevation.
    # Update the stored distance.
    hi_elev_dist.setDoubleValue(curr_dist);
  } else {
    # NO - we have passed the high elevation and need to reset.
    hi_elev_alt.setDoubleValue(-9999.9);
    hi_elev_lat.setDoubleValue(-9999.9);
    hi_elev_lon.setDoubleValue(-9999.9);
    hi_elev_dist.setDoubleValue(-9999.9);
  }
  tfa_radar_continuous_mode_full_scan();

  # Check that tfa is still engaged and re-schedule the next loop.
  # Also check that the mode hasn't changed.
  if(radar_state.getValue() == "on") {
    if(radar_mode.getValue() == "continuous") {
      settimer(tfa_radar_continuous_mode_loop, 0.1);
    } else {
      if(radar_mode.getValue() == "extend") {
        settimer(tfa_radar_extend_mode_loop, 0.1);
      }
    }
  }
}
#--------------------------------------------------------------------
var tfa_radar_extend_mode_loop = func {
  # This function checks to see if we are still approaching the high elevation
  # or whether we have passed it.
  # If we are still approaching it we perform an extend scan to check for a
  # higher elevation after the current high elevation.
  # If we have passed the current high elevation we do a full scan ahead to
  # find a new high elevation.

  var radar_state =  props.globals.getNode("/instrumentation/terrain-radar/settings/state");
  var radar_mode =   props.globals.getNode("/instrumentation/terrain-radar/settings/mode");
  var hi_elev_alt =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/alt-ft", 1);
  var hi_elev_lat =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lat-deg", 1);
  var hi_elev_lon =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lon-deg", 1);
  var hi_elev_dist = props.globals.getNode("/instrumentation/terrain-radar/hi-elev/dist-m", 1);

  # Set up a geo container for the stored high elevation location and validate it.
  var stor_coord = geo.Coord.new().set_latlon(hi_elev_lat.getValue(), hi_elev_lon.getValue());

  if(stor_coord.is_defined()) {
    # Get the current distance to the stored high elevation location.
    var curr_dist = geo.aircraft_position().distance_to(stor_coord);
  } else {
    # We've got a bad coord stored - zero it and re-scan.
    var curr_dist = 0;
  }

  # Test to see if we are still approaching the high elevation.
  if(curr_dist < hi_elev_dist.getValue()) {
    # YES - we are still approaching the high elevation.
    # Update the stored distance.
    hi_elev_dist.setDoubleValue(curr_dist);
    # Perfom an extend scan.
    tfa_radar_extend_mode_extend_scan();
  } else {
    # NO - we have passed the high elevation and need to perform a full scan.
    tfa_radar_extend_mode_full_scan();
  }

  # Check that tfa is still engaged and re-schedule the next loop.
  # Also check that the mode hasn't changed.
  if(radar_state.getValue() == "on") {
    if(radar_mode.getValue() == "continuous") {
      settimer(tfa_radar_continuous_mode_loop, 0.1);
    } else {
      if(radar_mode.getValue() == "extend") {
        settimer(tfa_radar_extend_mode_loop, 0.1);
      }
    }
  }
}
#--------------------------------------------------------------------
var tfa_radar_continuous_mode_full_scan = func {
  # This function scans the terrain ahead of the aircraft in steps and identifies
  # the highest ground elevation.  If it is higher than the stored high elevation
  # the stored high elevation is updated.

  var hi_elev_ft =   props.globals.getNode("/instrumentation/terrain-radar/hi-elev/alt-ft", 1);
  var hi_elev_lat =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lat-deg", 1);
  var hi_elev_lon =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lon-deg", 1);
  var hi_elev_dist = props.globals.getNode("/instrumentation/terrain-radar/hi-elev/dist-m", 1);
  var tfa_range =    props.globals.getNode("/instrumentation/terrain-radar/settings/range-m", 1);
  var tfa_step =     props.globals.getNode("/instrumentation/terrain-radar/settings/step-m", 1);
  var tgt_tfa_ft =   props.globals.getNode("/autopilot/internal/target-tfa-altitude-ft", 1);
  var tgt_agl_ft =   props.globals.getNode("/autopilot/settings/target-agl-ft", 1);
  var hdgdeg =       props.globals.getNode("/instrumentation/gps/indicated-track-true-deg", 1);
  var test =         -9999;

  for (dist = tfa_step.getValue(); tfa_range.getValue(); dist += tfa_step.getValue()) {
    var geo_coord = geo.aircraft_position().apply_course_distance(hdgdeg.getValue(), dist);
    if(geo_coord.is_defined()) {
      var geo_elev_m = geo.elevation(geo_coord.lat(), geo_coord.lon());

      # geo.elevation sometimes seems to return a bad value so test for it.
      if(geo_elev_m == nil) {
        geo_elev_m = 0;
      }

      # pick the highest point on the scan and store it (the test is in m but 
      # needs to be stored in ft)
      if(geo_elev_m > test) {
        test = geo_elev_m;
        var geo_elev_ft = geo_elev_m * 3.28;
        if(geo_elev_ft > hi_elev_ft.getValue()) {
          hi_elev_ft.setDoubleValue(geo_elev_ft);
          hi_elev_lat.setDoubleValue(geo_coord.lat());
          hi_elev_lon.setDoubleValue(geo_coord.lon());
          hi_elev_dist.setDoubleValue(dist);
          tgt_tfa_ft.setDoubleValue(geo_elev_ft + tgt_agl_ft.getValue());
          hi_elev_markers(geo_coord.lat(), geo_coord.lon());
        }
      }
    }
    if(dist >= tfa_range.getValue()) {
      break;
    }
  }
}
#--------------------------------------------------------------------
var tfa_radar_extend_mode_full_scan = func {
  # This function scans the terrain ahead of the aircraft in steps and identifies
  # the highest ground elevation.  It is only called when the current high
  # elevation point has been passed and a new high elevation is needed when in
  # extend mode but is called every time when in continuous mode.

  var hi_elev_ft =   props.globals.getNode("/instrumentation/terrain-radar/hi-elev/alt-ft", 1);
  var hi_elev_lat =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lat-deg", 1);
  var hi_elev_lon =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lon-deg", 1);
  var hi_elev_dist = props.globals.getNode("/instrumentation/terrain-radar/hi-elev/dist-m", 1);
  var tfa_range =    props.globals.getNode("/instrumentation/terrain-radar/settings/range-m", 1);
  var tfa_step =     props.globals.getNode("/instrumentation/terrain-radar/settings/step-m", 1);
  var tgt_tfa_ft =   props.globals.getNode("/autopilot/internal/target-tfa-altitude-ft", 1);
  var tgt_agl_ft =   props.globals.getNode("/autopilot/settings/target-agl-ft", 1);
  var hdgdeg =       props.globals.getNode("/instrumentation/gps/indicated-track-true-deg", 1);
  var test =         -9999;

  for (dist = tfa_step.getValue(); tfa_range.getValue(); dist += tfa_step.getValue()) {
    var geo_coord = geo.aircraft_position().apply_course_distance(hdgdeg.getValue(), dist);
    if(geo_coord.is_defined()) {
      var geo_elev_m = geo.elevation(geo_coord.lat(), geo_coord.lon());

      # geo.elevation sometimes seems to return a bad value so test for it.
      if(geo_elev_m == nil) {
        geo_elev_m = 0;
      }

      # pick the highest point on the scan and store it (the test is in m but 
      # needs to be stored in ft)
      if(geo_elev_m > test) {
        test = geo_elev_m;
        var geo_elev_ft = geo_elev_m * 3.28;
        hi_elev_ft.setDoubleValue(geo_elev_ft);
        hi_elev_lat.setDoubleValue(geo_coord.lat());
        hi_elev_lon.setDoubleValue(geo_coord.lon());
        hi_elev_dist.setDoubleValue(dist);
        tgt_tfa_ft.setDoubleValue(geo_elev_ft + tgt_agl_ft.getValue());
        hi_elev_markers(geo_coord.lat(), geo_coord.lon());
      }
    }
    if(dist >= tfa_range.getValue()) {
      break;
    }
  }
}
#--------------------------------------------------------------------
var tfa_radar_extend_mode_extend_scan = func {
  # This function scans the terrain at the full range ahead of the aircraft to
  # check for a new high elevation after tfa_radar_full_scan has identified the
  # initial high elevation. If a new higher elevation is found it updates the
  # current stored high elevation

  var hi_elev_ft =   props.globals.getNode("/instrumentation/terrain-radar/hi-elev/alt-ft", 1);
  var hi_elev_lat =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lat-deg", 1);
  var hi_elev_lon =  props.globals.getNode("/instrumentation/terrain-radar/hi-elev/lon-deg", 1);
  var hi_elev_dist = props.globals.getNode("/instrumentation/terrain-radar/hi-elev/dist-m", 1);
  var tfa_range =    props.globals.getNode("/instrumentation/terrain-radar/settings/range-m", 1);
  var tgt_tfa_ft =   props.globals.getNode("/autopilot/internal/target-tfa-altitude-ft", 1);
  var tgt_agl_ft =   props.globals.getNode("/autopilot/settings/target-agl-ft", 1);
  var hdgdeg =       props.globals.getNode("/instrumentation/gps/indicated-track-true-deg", 1);
  var geo_coord =    geo.aircraft_position().apply_course_distance(hdgdeg.getValue(), tfa_range.getValue());

  if(geo_coord.is_defined()) {
    var geo_elev_m = geo.elevation(geo_coord.lat(), geo_coord.lon());
    # Need to test in ft
    var geo_elev_ft = geo_elev_m * 3.28;
    if(geo_elev_ft > hi_elev_ft.getValue()) {
      # New high elevation.
      hi_elev_ft.setDoubleValue(geo_elev_ft);
      hi_elev_lat.setDoubleValue(geo_coord.lat());
      hi_elev_lon.setDoubleValue(geo_coord.lon());
      hi_elev_dist.setDoubleValue(tfa_range.getValue());
      tgt_tfa_ft.setDoubleValue(geo_elev_ft + tgt_agl_ft.getValue());
      hi_elev_markers(geo_coord.lat(), geo_coord.lon());
    }
  }
}
#--------------------------------------------------------------------
var hi_elev_markers = func(lat, lon) {
  marker_status =    props.globals.getNode("/instrumentation/terrain-radar/settings/hi-elev-markers", 1);

  if(htgt != nil) {
    htgt.remove();
  }

  if(marker_status.getValue()) {
    if(lat > -180) {
      htgt = geo.put_model("Aircraft/BAC-TSR2/Models/Elevation-marker.ac", lat, lon);
    }
  }
}
#--------------------------------------------------------------------
