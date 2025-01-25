    setlistener("/surface-positions/elevator-pos-norm", func(n) {
	position=n.getValue();
    setprop("/fdm/jsbsim/propulsion/engine[0]/pitch-angle-rad", position*0.35);
    setprop("/fdm/jsbsim/propulsion/engine[1]/pitch-angle-rad", position*0.35);
        },1);
    setlistener("/surface-positions/rudder-pos-norm", func(n) {
	position=n.getValue();
    setprop("/fdm/jsbsim/propulsion/engine[0]/yaw-angle-rad", position*-0.14);
    setprop("/fdm/jsbsim/propulsion/engine[1]/yaw-angle-rad", position*-0.14);
        },1);