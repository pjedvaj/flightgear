# Trajectory marker functions
#--------------------------------------------------------------------
toggle_traj_mkr = func {
  if(getprop("/ai/submodels/trajectory-markers") == nil) {
    setprop("/ai/submodels/trajectory-markers", 0);
  }
  if(getprop("/ai/submodels/trajectory-markers") < 1) {
    setprop("/ai/submodels/trajectory-markers", 1);
  } else {
    setprop("/ai/submodels/trajectory-markers", 0);
  }
}
#--------------------------------------------------------------------
