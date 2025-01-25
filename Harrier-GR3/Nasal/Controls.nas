# HARRIER controls
#  extra check to see if the harrier is carrying its AAR boom


var UPDATE_PERIOD = 0.3;


var update_loop = func {

    var hasAARBoom = getprop("sim/weight[7]/selected") != "none";
	var s = props.globals.getNode("systems/refuel/serviceable");
	s.setBoolValue(0);
    if ( hasAARBoom ){
        s.setBoolValue(1);
    }
	
    settimer(update_loop, UPDATE_PERIOD);
}


setlistener("/sim/signals/fdm-initialized", func {
	update_loop();
});
