    setlistener("/controls/engines/engine[0]/throttle", func(n) {
	position=n.getValue();
    setprop("/controls/engines/engine[0]/reheat",0);
        if(position > .99){

               setprop("/controls/engines/engine[0]/reheat",1);
     };
   },1);
    setlistener("/controls/engines/engine[1]/throttle", func(n) {
	position=n.getValue();
    setprop("/controls/engines/engine[1]/reheat",0);
        if(position > .99){

               setprop("/controls/engines/engine[1]/reheat",1);
     };
   },1);


ext_slats = func {
        print ("airspeed");
  airspeed = getprop("/velocities/airspeed-kt");
    if (airspeed < 180) {
      setprop("/controls/flight/slats", 1.0);
      } else {
        setprop("/controls/flight/slats", 0.0);

      }
     settimer(ext_slats, 0.5);
   }

ext_slats;


toggle_canopy = func {
  canopy = aircraft.door.new ("/controls/canopy/",3);
  if(getprop("/controls/canopy/position-norm") > 0) {
      canopy.close();
  } else {

      canopy.open();
  }
}
