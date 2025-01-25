#HOWTO: add new weapon type
#-add new entry inside <weight> in -set.xml (for all pylons where
# it can be mounted)
#-add new int resolver in setLoadInt() below (with yet unused value)
#-add necessary animation/model show code in proper places in the
# ALCA/Models folder

var weightsNode = props.globals.getNode("/sim");
var numWeights = 9;

for(var i=0; i<numWeights; i+=1) {
	props.globals.initNode("/sim/weight["~i~"]/payload-int", 0, "INT");
}



#function for resolving MP transferred load type int
#all weapon types have this value identical on all pylons
#(even if some types are not available there)
var setLoadInt = func(pylon_index) {
	var payload = getprop("/sim/weight["~pylon_index~"]/selected");
	#print("Index:" ~ pylon_index ~ "  Payload: " ~ payload);
	if( payload == "None" or payload == "Mount only used pylons" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 0);
	else if( payload == "Mount all pylons" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 1);
	else if( payload == "AIM-9" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 2);
	else if( payload == "PL-20 Plamen" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 3);
	else if( payload == "AGM-65 Maverick" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 4);
	else if( payload == "GBU-12 Paveway II" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 5);
	else if( payload == "GBU-16 Paveway II" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 6);
	else if( payload == "Mk82" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 7);
	else if( payload == "Mk83" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 8);
	else if( payload == "350l Tactical droptank" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 9);
	else if( payload == "500l Ferry droptank" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 10);
	else if( payload == "Probe mounted" ) {
		setprop("/systems/refuel/serviceable", 1);
		setprop("/sim/weight["~pylon_index~"]/payload-int", 11);
	}
	else if( payload == "Smokewinder" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 12);
	else if( payload == "No probe" ) {
		setprop("/systems/refuel/serviceable", 0);
		setprop("/sim/weight["~pylon_index~"]/payload-int", 0);
	}
	
		
	#error case - weapon from payloads dialog not implemented here
	else setprop("/sim/weight["~pylon_index~"]/payload-int", -1);
	
	#print("resolving weight int for pylon "~pylon_index);
}

forindex(var i; weightsNode.getChildren("weight")) {
	setlistener("/sim/weight["~i~"]/selected", func{setLoadInt(arg[0].getParent().getIndex());}, 1, 0); #need to get the node index in this way, if I just put in i it would use the highest number from last loop iteration at all times...
	#print("setting listener for pylon "~i);
}



print("ALCA payload system initialized");