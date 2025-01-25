#props.globals.initNode("controls/switches/canopy", 0, "BOOL");
#props.globals.initNode("/canopy/position-norm", 0, "DOUBLE");
#
#var canopy_time = 5;
#var canopy_toggle = func {
#	var canopy_switch = getprop("controls/switches/canopy");
#	if ( canopy_switch == 1 ) { 
#		interpolate("/canopy/position-norm", 1, 
#			canopy_time*(1-getprop("/canopy/position-norm")) ); 
#	}
#	if ( canopy_switch == 0 ) { 
#		interpolate("/canopy/position-norm", 0, 
#			canopy_time*(getprop("/canopy/position-norm")) ); 
#	}
#}
#    
#setlistener("/controls/switches/canopy", canopy_toggle);

var canopy = aircraft.door.new("/canopy", 8);
