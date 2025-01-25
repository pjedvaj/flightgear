# for Machine Gun
fire_MG = func {
	            setprop("/controls/armament/trigger", 1);
		   }

stop_MG = func {
			setprop("/controls/armament/trigger", 0); 
		   }

var flash_trigger = props.globals.getNode("controls/armament/trigger", 0);



# for Hydra 70
fire_Hydra = func {
                      setprop("/controls/armament/trigger1", 1);
			 }

stop_Hydra = func {
			    setprop("/controls/armament/trigger1", 0); 
			 }

var flash_trigger1 = props.globals.getNode("controls/armament/trigger1", 0);



# for AIM-92 Stinger

fire_Stinger = func {
                      setprop("/controls/armament/trigger2", 1);
			 }

stop_Stinger = func {
			    setprop("/controls/armament/trigger2", 0); 
			 }

var flash_trigger2 = props.globals.getNode("controls/armament/trigger2", 0);



# for AGM-114 Hellfire

fire_Hellfire = func {
                      setprop("/controls/armament/trigger3", 1);
			 }

stop_Hellfire = func {
			    setprop("/controls/armament/trigger3", 0); 
			 }

var flash_trigger3 = props.globals.getNode("controls/armament/trigger3", 0);