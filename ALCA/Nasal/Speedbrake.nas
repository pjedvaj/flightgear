var overspeed = 0;

var speedCheck = func {
	var kias = getprop("/velocities/airspeed-kt");
	var spbrakePos = getprop("/controls/flight/speedbrake");
	if(kias == nil or spbrakePos == nil)
		return;
	
	if(kias > 518 and spbrakePos == 0 ) {
		overspeed = 1;
		setprop("/controls/flight/speedbrake", 1);
		screen.log.write("Speed exceeds Vne, deploying speedbrake!");
	}
	else if(overspeed and kias < 480 ) {
		overspeed = 0;
		setprop("/controls/flight/speedbrake", 0);
		screen.log.write("Speed reduced sufficiently, retracting speedbrake");
	}
}