#PC-9M systems
#Hyde Yamakawa
#
setlistener("/sim/signals/fdm-initialized", func {
    settimer(start_updates,1);
});

var systems_running = 0;
var start_updates = func {
    if (getprop("position/altitude-agl-ft")>30)
    {
        # airborne startup
		setprop("fdm/jsbsim/systems/canopy/command", 0);
		setprop("fdm/jsbsim/systems/canopy/position", 0);
		setprop("canopy/position-norm", 0);
		setprop("/controls/engines/engine[0]/starter", 1);
		settimer(func { setprop("/controls/engines/engine[0]/cutoff", 0); }, 1);
		setprop("/controls/gear/gear-down", 0);
        setprop("/controls/gear/brake-parking",0);
		setprop("autopilot/settings/target-speed-kt", getprop("sim/presets/airspeed-kt"));
		setprop("instrumentation/afds/inputs/at-armed", 1);
		setprop("instrumentation/afds/inputs/AP", 1);
        setprop("autopilot/settings/heading-bug-deg", getprop("sim/presets/heading-deg"));
        setprop("autopilot/settings/counter-set-altitude-ft", getprop("sim/presets/altitude-ft"));
		PC9M.afds.input(1,2);
        setprop("autopilot/settings/vertical-speed-fpm", 2000);
		setprop("controls/flight/rudder-trim", 0);
		setprop("controls/flight/elevator-trim", 0);
		setprop("controls/flight/aileron-trim", 0);
    }

    # start update_systems loop - but start it once only
    if (!systems_running)
    {
        systems_running = 1;
#        update_systems();
    }
}

var update_systems = func {
    settimer(update_systems,0);
}

