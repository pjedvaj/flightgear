props.globals.initNode("/disintegration/spinSpeed", 0, "DOUBLE");
props.globals.initNode("/disintegration/crashTime", 0, "DOUBLE");
props.globals.initNode("/disintegration/negAGL", 0, "DOUBLE");
props.globals.initNode("/disintegration/severity", 1, "DOUBLE");

props.globals.initNode("/disintegration/parts");
var partsNode = props.globals.getNode("/disintegration/parts");

var degToRad = 3.141592654/180;
var kt2mps = 0.51444;
var ft2m = 0.3048;
var maxSpin = 36; #0.6 rev/s
var baseSpin = 4; 
var g = 9.81;

var crashSlow = 0.3; #factor by which is fwd movement slowed after crash

#function for initializing parts
var initPart = func(name, dX, dY, dZ, vX=0, vY=0, vZ=0) {
	#geometrical center of the element
	props.globals.initNode("/disintegration/parts/"~name~"/dX", dX, "DOUBLE");
	props.globals.initNode("/disintegration/parts/"~name~"/dY", dY, "DOUBLE");
	props.globals.initNode("/disintegration/parts/"~name~"/dZ", dZ, "DOUBLE");
	#initial velocities, in local coords
	props.globals.initNode("/disintegration/parts/"~name~"/vX", vX, "DOUBLE");
	props.globals.initNode("/disintegration/parts/"~name~"/vX-base", vX, "DOUBLE");
	props.globals.initNode("/disintegration/parts/"~name~"/vY", vY, "DOUBLE");
	props.globals.initNode("/disintegration/parts/"~name~"/vY-base", vY, "DOUBLE");
	props.globals.initNode("/disintegration/parts/"~name~"/vZ", vZ, "DOUBLE");
	props.globals.initNode("/disintegration/parts/"~name~"/vZ-base", vZ, "DOUBLE");
	#stops the animation after part specific fall time
	props.globals.initNode("/disintegration/parts/"~name~"/falling", 0, "BOOL");
	props.globals.initNode("/disintegration/parts/"~name~"/dropped", 0, "BOOL");
}

#calls of previous function to initialize parts
initPart("wingL", 0.15410, -2.26975, -0.77074, 0.4, 0.9, 0.7);
initPart("wingR", 0.15410, 2.26975, -0.77074, -0.6, -1.2, -0.4);
initPart("fuselage", 0, 0, 0, 0.3, -0.1, 0.3);
initPart("engine", 4.53874, 0.008699, -0.16101, 0.2, -0.15, -0.05);
initPart("leftGear", 0.42088, -1.37051, -1.75547, -0.1, 0.42, -0.14);
initPart("rightGear", 0.42088, 1.39580, -1.75547, -0.12, -0.31, -0.09);
initPart("tipTankL", 0.11227, -4.68805, -0.66387, 0.13, 1.35, 0.45);
initPart("tipTankR", 0.11227, 4.70542, -0.66387, 0.25, -1.61, -0.21);
initPart("horizStabL", 4.73850, -1.29339, 0.23392, -0.61, -1.1, 0.24);
initPart("horizStabR", 4.73850, 1.31096, 0.23392, -0.75, -1.3, -0.15);
initPart("canopy", -2.33956, 0.008221, 0.35475, 1.25, 0.12, 1.68);
initPart("seatFront", -2.97869, 0.003534, -0.27471, 0.94, -0.32, 1.52);
initPart("seatRear", -1.62999, -0.00342, -0.06229, 1.15, 0.15, 1.38);
initPart("cockpit", -3.2, 0.0, -0.4, -2.32, -0.23, -0.50);
initPart("frontGear", -4.4105, 0.0, -1.4000, -1.35, 0.13, -0.62);
initPart("intake", -0.4700, 0.0, -0.06699, 0.75, -0.11, 2.4);
initPart("rudder", 5.0500, 0.0, 1.5818, -0.52, 0.21, 0.8);
initPart("airbrake", -0.55945, 0.0, -1.08122, -0.15, 0.11, -0.75);
initPart("aileronL", 0.88190, -3.97498, -0.70136, 0.42, 0.93, 0.64);
initPart("aileronR", 0.88499, 3.99640, -0.70138, -0.57, -1.23, -0.23);
initPart("flapL", 1.34842, -1.97041, -0.78875, 0.38, 0.36, 0.59);
initPart("flapR", 1.34842, 1.98778, -0.78875, -0.37, -0.19, -0.11);
initPart("elevatorL", 5.27882, -1.00246, 0.23300, -0.82, -0.2, 0.08);
initPart("elevatorR", 5.27813, 1.01228, 0.23218, -1.3, -2.1, -0.05);
#stores
initPart("R1", 0.0, 1.9820, -1.2831, -0.08, -0.62, -0.12);
initPart("L1", 0.0, -1.96496, -1.2831, -0.15, 1.10, -0.09);
initPart("R2", 0.0801, 2.6996, -1.2297, -0.11, -1.8, -0.11);
initPart("L2", 0.0801, -2.6828, -1.2831, -0.18, 2.25, -0.06);
initPart("R3", -0.3223, 3.4567, -1.1716, -0.15, -2.9, -0.13);
initPart("L3", -0.3223, -3.4395, -1.1716, -0.21, 2.68, -0.17);
initPart("C", -2.043, 0.0087, -1.5200, -1.52, 0.15, -0.65);


var partsList = partsNode.getChildren();

#function for computing part specific stuff
var setPart = func(name, AGL, groundspeed, severity, ground) {
	var pitch = degToRad * getprop("/orientation/pitch-deg");
	var roll = degToRad * getprop("/orientation/roll-deg");
	
	var globalVZ = ground * (2 * severity + 2 * severity * math.abs(math.sin(pitch)) + 0.04 * crashSlow * groundspeed * severity * math.abs(math.sin(pitch) * math.cos(pitch)));
	
	
	var heightX = (getprop("/disintegration/parts/"~name~"/dX")) * math.sin(pitch);
	var heightY = (getprop("/disintegration/parts/"~name~"/dY")) * math.cos(pitch) * math.sin(roll);
	var heightZ = (getprop("/disintegration/parts/"~name~"/dZ")) * math.cos(pitch) * math.cos(roll);
	
	var height = AGL + heightX + heightY + heightZ;
	
	setprop("/disintegration/parts/"~name~"/vX", 
		severity * getprop("/disintegration/parts/"~name~"/vX-base") + 
		groundspeed * kt2mps * crashSlow + 
		globalVZ * math.sin(pitch)
	);
	
	setprop("/disintegration/parts/"~name~"/vY", 
		severity * getprop("/disintegration/parts/"~name~"/vY-base") + 
		globalVZ * math.cos(pitch) * math.sin(roll)
	);
	setprop("/disintegration/parts/"~name~"/vZ", 
		severity * getprop("/disintegration/parts/"~name~"/vZ-base") + 
		globalVZ * math.cos(pitch) * math.cos(roll)
	);
	
	
	var velX = getprop("/disintegration/parts/"~name~"/vX") * math.sin(pitch);
	var velY = getprop("/disintegration/parts/"~name~"/vY") * math.cos(pitch) * math.sin(roll);
	var velZ = getprop("/disintegration/parts/"~name~"/vZ") * math.cos(pitch) * math.cos(roll);
	
	var upV = velX + velY + velZ;
	
	var fallTime = (upV*upV + 2*g*height)>0 ? (upV + math.sqrt(upV*upV + 2*g*height))/g : upV/g;
	
	#print("name:"~name~" height:"~height~" fallTime:"~fallTime);
	
	setprop("/disintegration/parts/"~name~"/falling", 1);
	settimer(func{setprop("/disintegration/parts/"~name~"/falling", 0);}, fallTime>0 ? fallTime : 0);
	setprop("/disintegration/parts/"~name~"/dropped", 1);
}

var getSeverity = func {
	uBody = getprop("velocities/uBody-fps");
	vBody = getprop("velocities/vBody-fps");
	wBody = getprop("velocities/wBody-fps");
	var speed = ft2m * math.sqrt(uBody*uBody + vBody*vBody + wBody*wBody);
	return 10 - (1000/(speed + 100)); 
}

#fwd is based on groundspeed, side and up on impact severity

var disintegrated = 0;
var disintegrate = func(override=0, gr=nil, sev=nil) {
	if(disintegrated == 0 and (getprop("/sim/crashed") or override)) {
		disintegrated = 1;
		setprop("/sim/crashed", 1);
		setprop("/disintegration/crashTime", getprop("/sim/time/elapsed-sec"));
		
		var groundspeed = getprop("/velocities/groundspeed-kt");
		var negAGL = -0.3048 * getprop("/position/altitude-agl-ft");
		setprop("/disintegration/negAGL", negAGL);
		
		var severity = 0;
		if(sev==nil) {
			severity = getSeverity();
		}
		else {
			severity = sev;
		}
		
		var ground = 0;
		if(gr==nil) {
			if(negAGL < -15) {
				ground = 0;
			}
			else {
				ground = 1;
			}
		}
		else {
			ground = gr;
		}
		
		if(severity>5) {
			explosion.explode(ground);
		}
		
		setprop("/disintegration/severity", severity);
		setprop("/disintegration/spinSpeed", 0);
		interpolate("/disintegration/spinSpeed", (severity*baseSpin)>maxSpin ? maxSpin : severity*baseSpin, 0.15);
		settimer(func{interpolate("/disintegration/spinSpeed", baseSpin, 3);}, 0.15);
		
		#loop over all parts and prepare them for animation
		foreach(var p; partsList) {
			setPart(p.getName(), -negAGL, groundspeed, severity, ground);
		}
		
	}
	else {
		if(getprop("/sim/crashed") == 0 and disintegrated == 1) {
			disintegrated = 0;
			explosion.stopFire();
			#set all falling to 1 briefly to enable position reset
			foreach(var p; partsList) {
				var nameStr = p.getName();
				setprop("/disintegration/parts/"~nameStr~"/falling", 1);
				settimer(func{setprop("/disintegration/parts/"~nameStr~"/falling", 0);}, 0.3);
				setprop("/disintegration/parts/"~nameStr~"/dropped", 0);
			}
		}
	}
}

setlistener("/sim/crashed", func{disintegrate();});



