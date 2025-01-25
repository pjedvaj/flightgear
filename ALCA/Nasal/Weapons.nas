
#PL-20 Plamen trigger

#initialize triggers
props.globals.initNode("/controls/armament/trigger", 0, "BOOL");
props.globals.initNode("/controls/armament/mode-fast", 0, "BOOL");
#fast variant: 2600 rounds/min
props.globals.initNode("/controls/armament/trigger-fastPlamenC", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-fastPlamenR", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-fastPlamenL", 0, "BOOL");
#slow variant: 780 rounds/min
props.globals.initNode("/controls/armament/trigger-slowPlamenC", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-slowPlamenR", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-slowPlamenL", 0, "BOOL");

props.globals.initNode("/sim/multiplay/generic/int[6]", 0, "INT");

var maxAmmo = 210;

var ammoPopup = func {
	gui.popupTip("Plamen rounds left: " ~ int(getprop("/controls/armament/roundsCount")));
}

#ammo counter
props.globals.initNode("/controls/armament/roundsLeft", maxAmmo, "INT");
props.globals.initNode("/controls/armament/roundsCount", maxAmmo, "DOUBLE");
var reloadPlamen = func {
	if( getprop("/gear/gear[0]/wow") 
	and getprop("/gear/gear[1]/wow") 
	and getprop("/gear/gear[2]/wow") 
	and (getprop("/velocities/groundspeed-kt") < 2) ) {
		setprop("/controls/armament/roundsLeft", maxAmmo);
		setprop("/controls/armament/roundsCount", maxAmmo);
		if(getprop("/controls/armament/report-ammo"))
			ammoPopup();
	}
	else {
		screen.log.write("You must be stopped on the ground for reloading!", 1, 0.6, 0.1);
	}
}

#A resource friendly way of ammo counting: Instead of counting every bullet, I set an interpolate on float variant of ammo counter. But I need a timer to cut off fire when out of ammo. 

var outOfAmmo = maketimer(1.0, 
	func { 
		#print("Out of ammo! ");
		setprop("/controls/armament/trigger-fastPlamenC", 0);
		setprop("/controls/armament/trigger-fastPlamenR", 0);
		setprop("/controls/armament/trigger-fastPlamenL", 0);
		setprop("/controls/armament/trigger-slowPlamenC", 0);
		setprop("/controls/armament/trigger-slowPlamenR", 0);
		setprop("/controls/armament/trigger-slowPlamenL", 0);
		setprop("/sim/multiplay/generic/int[6]", 0);
		setprop("/controls/armament/roundsCount", 0);
		setprop("/controls/armament/roundsLeft", 0);
	}
);
outOfAmmo.singleShot = 1;

var ammoReport = maketimer(0.02, ammoPopup);
ammoReport.singleShot = 0;

#check which cannons are mounted, set their own triggers
var triggerControl = func {
	triggerState = getprop("controls/armament/trigger");
	if(triggerState and getprop("/controls/armament/roundsLeft") > 0) {
		var pylonC = getprop("/sim/weight[4]/payload-int");
		var pylonR = getprop("/sim/weight[3]/payload-int");
		var pylonL = getprop("/sim/weight[5]/payload-int");
		
		if(pylonC == 3 or pylonR == 3 or pylonL == 3) {
			if(getprop("/controls/armament/mode-fast")) {
				var fireTime = 4.846; #continuous fire for 2600 r/min
				if(pylonC == 3)
					setprop("/controls/armament/trigger-fastPlamenC", 1);
				if(pylonR == 3)
					setprop("/controls/armament/trigger-fastPlamenR", 1);
				if(pylonL == 3)
					setprop("/controls/armament/trigger-fastPlamenL", 1);
				setprop("/sim/multiplay/generic/int[6]", 2);
			}
			else {
				var fireTime = 16.154; #continuous fire for 780 r/min
				if(pylonC == 3)
					setprop("/controls/armament/trigger-slowPlamenC", 1);
				if(pylonR == 3)
					setprop("/controls/armament/trigger-slowPlamenR", 1);
				if(pylonL == 3)
					setprop("/controls/armament/trigger-slowPlamenL", 1);
				setprop("/sim/multiplay/generic/int[6]", 1);
		
			}
			var roundsLeft = getprop("/controls/armament/roundsLeft");
			setprop("/controls/armament/roundsCount", roundsLeft);
			interpolate("/controls/armament/roundsCount", 0, 
				fireTime*(roundsLeft/maxAmmo));
			outOfAmmo.restart(fireTime*(roundsLeft/maxAmmo));
			if(getprop("/controls/armament/report-ammo")) 
				ammoReport.start();
		}
	}
	else {
		setprop("/controls/armament/trigger-fastPlamenC", 0);
		setprop("/controls/armament/trigger-fastPlamenR", 0);
		setprop("/controls/armament/trigger-fastPlamenL", 0);
		setprop("/controls/armament/trigger-slowPlamenC", 0);
		setprop("/controls/armament/trigger-slowPlamenR", 0);
		setprop("/controls/armament/trigger-slowPlamenL", 0);
		
		setprop("/sim/multiplay/generic/int[6]", 0);
		
		setprop("/controls/armament/roundsLeft", 
			getprop("/controls/armament/roundsCount"));#gets truncated
		interpolate("/controls/armament/roundsCount", 
			getprop("/controls/armament/roundsLeft"), 0);
		outOfAmmo.stop();
		ammoReport.stop();
		#ammo count report on trigger release
		if(getprop("/controls/armament/roundsLeft")==0 and getprop("/controls/armament/report-ammo"))
			ammoPopup();
	}
}


setlistener("controls/armament/trigger", triggerControl);


print("ALCA weapons system initialized");