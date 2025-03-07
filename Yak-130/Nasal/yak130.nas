	## Settings
	
	###
	# Owner Options
	var difficulty         = 0; # Set to 1 for advanced handling options e.g. engine overspeed, mach trim etc.
	var real_maintenance   = 1; # Set to 1 for real maintenance conditions
	var maintenance_report = 1; # Set to 1 for a console maintenance report at startup
	
	###
	# Propery Roots - usually no need to change these
	var diff_root = "sim/difficulty";
	var rm_root   = "sim/maintenance";
    
	var doorpath = "canopy";
	var doorpos = 1; 
	
	###
	# Presets 
	
	var acname = "yak130"; # Script Display Name
	var main_loop_interval = 1; # Main loop update period in seconds
	var aux_loop_interval = 60; # Auxiliary loop update period in seconds
	
	################################
	## Objects	
		
	###
	# Engines
	
	 var engines = { 
         # Arguments: ( number, running, idle_throttle, max_start_n1, start_threshold, spool_time, start_time, shutdown_time)
         #Jet.new(4 , 0 , 0.105 , 10 , 6 , 1 , 0.05 , 3);
         engine1: yasimengines.Jet.new(0 , 0 , 0.005 , 12.8 , 10 , 6.9 , 0.05 , 1),
         engine2: yasimengines.Jet.new(1 , 0 , 0.005 , 12.8 , 10 , 6.9 , 0.05 , 1),
        };
	
	###
	# Doors ( & Canopies )
	
	# Arguments: ( property path, seconds, start position )
	var canopy = aircraft.door.new(doorpath, 5, 1);		
	
	###
	# Lights
	var lightpath = "sim/model/lights";
	
	###
	# Airbrakes
	
	###
	# Saved Data
	
	aircraft.data.load();
	
	var savedata = [
	     # This is a list of properties saved to disk every 60 seconds
		"sim/maintenance/airframe-seconds",
		"sim/maintenance/engine[0]/operating-seconds",
		"sim/maintenance/engine[1]/operating-seconds",
	
	];
	aircraft.data.add(savedata);
	
	################################
	## Initialisation & Internals
	
	### 
	# Loading Message
	print("Loading "~acname~" Master Nasal");
	
			
	# Check installed modules
	var eng_loaded = props.globals.getNode("nasal/yasimengines/loaded").getBoolValue();
	var rm_loaded = props.globals.getNode("nasal/maintenance/loaded").getBoolValue();
	var el_loaded = 0;
	
	###
    # Main Initialise Function
    var init = func {
	   
		print("Initialising "~acname~" Master Nasal...");
		
		var diff_status = "Easy";
		var rm_status = "Off";
		
		if ( props.globals.getNode(diff_root~"/difficult-mode",1).getBoolValue() ) {
		     difficulty = 1;
			}
		
		if ( difficulty ) {	var diff_status = "Difficult" };
		
		# Check loaded modules
		
		if ( rm_loaded ) { 
		
		     print("Maintenance module loaded");
			 
			 if ( real_maintenance ) {
		         var rm_status = "On"; 
			    #print("  - Airframe Hours: " ~afhours);
		         maintenance.init();
			     maintenance.airframe_hours();	
				
				if ( maintenance_report ) {
				     print("\nMaintenance Report:\n==================\n");
                     var mrep = maintenance.report();
                     print (mrep);					 
				    }
				}
			}
			
		 if  ( el_loaded ) {
		     print("Electrical System module loaded");
			}
		
		print("  - Difficulty setting: "~diff_status);
		print("  - Maintenance Mode: "~rm_status);
		
		props.globals.getNode(diff_root~"/difficult-mode",1).setBoolValue(difficulty);
		props.globals.getNode(rm_root~"/enabled",1).setBoolValue(real_maintenance);

		eno.init();
		engines.engine1.init();
		engines.engine2.init();
		auxloop.start();
		
	}
	
	###
	# Difficulty
	var diffprop = props.globals.getNode( diff_root~"/difficult-mode",1 );
	if ( diffprop.getBoolValue() ) { difficulty = 1 };
	diffprop.setBoolValue(difficulty);
	
	###
	# Maintenance
	
	###
	# Loops
	
	var loops = {
	     main: func {
		     
			},
	     aux: func {
		     # print("Aux Loop Looping!"); #Debug
		     if ( props.globals.getNode(rm_root~"/enabled",1).getBoolValue() ) { maintenance.rm_loop(); }
			 
			 # Save
			 aircraft.data.save();
		    },
	};
	
	###
	# Timers
	
	var auxloop = maketimer(aux_loop_interval,loops.aux);
	
	###
	# Go!
	
	setlistener("sim/signals/fdm-initialized", func {
	     settimer( init, 2);
	    });