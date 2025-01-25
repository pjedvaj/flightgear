var V1_explode = props.globals.getNode("sim/multiplay/generic/int[1]");
var V1_fire = props.globals.getNode("sim/multiplay/generic/int[2]");
				
var V1_DetonateControl = 0; #used to check double Shift-D trigger

				
V1_explode.setIntValue(0);
V1_fire.setIntValue(0);
setprop("/autopilot/settings/target-altitude-ft", 0);

#automatic detonation on impact, with fire
var listener_explode = setlistener("sim/crashed", 
	func {
		if( getprop("sim/multiplay/generic/int[2]") < 1 and getprop("sim/crashed") ){
			V1_explode.setIntValue(1);
			V1_fire.setIntValue(1);
			settimer( func {
				V1_explode.setIntValue(0);} , 0.2);
		}
	}
);

#manual detonation, temporary fire
var detonate = func {
	if ( V1_DetonateControl and getprop("sim/multiplay/generic/int[2]") < 1 ){
		
		setprop("controls/engines/engine/throttle", 0);
		setprop("/controls/flight/elevator", 1);
		setprop("/autopilot/settings/target-altitude-ft", -5000);
		V1_explode.setIntValue(1);
		V1_fire.setIntValue(2);
		settimer( func {
			V1_explode.setIntValue( 0);
			} , 0.2);
		settimer( func {
			V1_fire.setIntValue(3);
			} , 20);
	}
	else {
		V1_DetonateControl = 1;
		settimer( func {
			V1_DetonateControl = 0;
			} , 2);
	}
}

#reset the explosive load
var rearm = func {
	V1_fire.setIntValue(0);
}

