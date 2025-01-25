
lights_dialog = gui.Dialog.new("/sim/gui/dialogs/ALCA/lights-dialog/dialog", "Aircraft/ALCA/Dialogs/LightsDialog.xml");

props.globals.initNode("/controls/armament/flares-release", 0, "BOOL");
props.globals.initNode("/controls/armament/chaff-release", 0, "BOOL");

props.globals.initNode("/controls/armament/report-ammo", 0, "BOOL");


#global periodical checks loop - the only periodical stuff not included is fuel system
var globalLoop = 0.1;
var globalChecks = func {
	weight.weightCheck();
	flaps.flapCheck();
	speedbrake.speedCheck();
	
	settimer(globalChecks, globalLoop);
}
globalChecks();

setprop("/sim/current-view/view-number", 0);
setprop("/sim/current-view/field-of-view", getprop("/sim/view/config/default-field-of-view-deg"));