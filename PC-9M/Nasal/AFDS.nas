#############################################################################
# PC-9M Autopilot Flight Director System
# Hyde Yamakawa
#
# speed modes: SPD;
# roll modes : HDG SEL,HDG HOLD, LNAV, LOC;
# pitch modes: ALT, V/S, G/S;
# FPA range  : -9.9 ~ 9.9 degrees
# VS range   : -8000 ~ 6000
# ALT range  : 0 ~ 50,000
# KIAS range : 100 ~ 399
# MACH range : 0.40 ~ 0.95
#
#############################################################################

#Usage : var afds = AFDS.new();

var copilot = func(msg) { setprop("/sim/messages/copilot",msg);}

var AFDS = 
{
	new : func
	{
		var m = {parents:[AFDS]};

		m.spd_list=["","SPD"];

		m.roll_list=["","HDG HOLD","LNAV","LOC"];

		m.pitch_list=["","ALT","V/S","G/S"];

		m.step=0;
		m.remaining_distance_log_last = 36000;
		m.heading_change_rate = 0.4 * 0.7;

		m.AFDS_node = props.globals.getNode("instrumentation/afds",1);
		m.AFDS_inputs = m.AFDS_node.getNode("inputs",1);
		m.AFDS_apmodes = m.AFDS_node.getNode("ap-modes",1);
		m.AFDS_settings = m.AFDS_node.getNode("settings",1);
		m.AP_settings = props.globals.getNode("autopilot/settings",1);

		m.AP = m.AFDS_inputs.initNode("AP",0,"BOOL");
		m.AP_disengaged = m.AFDS_inputs.initNode("AP-disengage",0,"BOOL");
		m.AP_passive = props.globals.initNode("autopilot/locks/passive-mode",1,"BOOL");
		m.AP_pitch_engaged = props.globals.initNode("autopilot/locks/pitch-engaged",1,"BOOL");
		m.AP_roll_engaged = props.globals.initNode("autopilot/locks/roll-engaged",1,"BOOL");

		m.FD = m.AFDS_inputs.initNode("FD",0,"BOOL");
		m.at1 = m.AFDS_inputs.initNode("at-armed",0,"BOOL");
		m.autothrottle_mode = m.AFDS_inputs.initNode("autothrottle-index",0,"INT");
		m.lateral_mode = m.AFDS_inputs.initNode("lateral-index",0,"INT");
		m.vertical_mode = m.AFDS_inputs.initNode("vertical-index",0,"INT");
		m.gs_armed = m.AFDS_inputs.initNode("gs-armed",0,"BOOL");
		m.loc_armed = m.AFDS_inputs.initNode("loc-armed",0,"BOOL");
		m.vor_armed = m.AFDS_inputs.initNode("vor-armed",0,"BOOL");
		m.lnav_armed = m.AFDS_inputs.initNode("lnav-armed",0,"BOOL");
		m.estimated_time_arrival = m.AFDS_inputs.initNode("estimated-time-arrival",0,"INT");
		m.remaining_distance = m.AFDS_inputs.initNode("remaining-distance",0,"DOUBLE");;
        m.vs_ind =  props.globals.initNode("autopilot/internal/vert-speed-fpm",0,"DOUBLE");

		m.heading_magnetic = m.AFDS_settings.getNode("heading-magnetic",1);

		m.AP_roll_mode = m.AFDS_apmodes.initNode("roll-mode","");
		m.AP_pitch_mode = m.AFDS_apmodes.initNode("pitch-mode","");
		m.AP_speed_mode = m.AFDS_apmodes.initNode("speed-mode","");

		m.ias_setting = m.AP_settings.initNode("target-speed-kt",150);# 100 - 399 #
		m.vs_setting = m.AP_settings.initNode("vertical-speed-fpm",0); # -8000 to +6000 #
		m.hdg_setting = m.AP_settings.initNode("heading-bug-deg",360,"INT"); # 1 to 360
		m.alt_setting = m.AP_settings.initNode("counter-set-altitude-ft",5000,"DOUBLE");
		m.target_alt = m.AP_settings.initNode("actual-target-altitude-ft",5000,"DOUBLE");

		m.APl = setlistener(m.AP, func m.setAP(),0,0);
		m.APdisl = setlistener(m.AP_disengaged, func m.setAP(),0,0);
		return m;
	},
####  Inputs   ####
###################
	input : func(mode,btn)
	{
#		if(getprop("/systems/electrical/outputs/avionics"))
#		{
			var current_alt = getprop("instrumentation/altimeter/indicated-altitude-ft");
			if(mode==0)
			{
				# horizontal AP controls
				if(btn == 1)		# Heading button
				{
					# set target to current magnetic heading
					var tgtHdg = int(me.heading_magnetic.getValue() + 0.50);
					me.hdg_setting.setValue(tgtHdg);
				}
				elsif(btn==2)		# LNAV button
				{
					if ((!getprop("/autopilot/route-manager/active"))or
						(getprop("/autopilot/route-manager/current-wp")<0)or
						(getprop("/autopilot/route-manager/wp/id")==""))
					{
						# Oops, route manager isn't active. Keep current mode.
						btn = me.lateral_mode.getValue();
						copilot("Instractor:LNAV doesn't engage. We forgot to program or activate the route manager!");
					}
					else
					{
						if(me.lateral_mode.getValue() == 2)		# Current mode is LNAV
						{
							# set target to current magnetic heading
							var tgtHdg = int(me.heading_magnetic.getValue() + 0.50);
							me.hdg_setting.setValue(tgtHdg);
							btn = 1;	# Heading sel
						}
						elsif(me.lnav_armed.getValue())
						{	# LNAV armed then disarm
							me.lnav_armed.setValue(0);
							btn = me.lateral_mode.getValue();
						}
						else
						{	# LNAV arm
							me.lnav_armed.setValue(1);
							btn = me.lateral_mode.getValue();
						}
					}
				}
				me.lateral_mode.setValue(btn);
			}
			elsif(mode==1)
			{
				# vertical AP controls
				if (btn==1)
				{
					# hold current altitude
					if(me.AP.getValue() or me.FD.getValue())
					{
						var alt = int((current_alt+50)/100)*100;
						me.target_alt.setValue(alt);
#						me.autothrottle_mode.setValue(5);	# A/T SPD
					}
				}
				if(btn==2)
				{
					# hold current vertical speed
					var vs = me.vs_ind.getValue();
					vs = int(vs/100)*100;
					if (vs<-8000) vs = -8000;
					if (vs>6000) vs = 6000;
					me.vs_setting.setValue(vs);
					me.target_alt.setValue(me.alt_setting.getValue());
#					me.autothrottle_mode.setValue(5);	# A/T SPD
				}
				me.vertical_mode.setValue(btn);
			}
			elsif(mode == 2)
			{
				# throttle AP controls
				if(me.autothrottle_mode.getValue() != 0
					or (me.at1.getValue() == 0))
				{
					btn = 0;
				}
				elsif(getprop("position/altitude-agl-ft") > 400) # above baro 400 ft
				{
					btn=0;
					copilot("Auto-throttle won't engage below 400ft.");
				}
				me.autothrottle_mode.setValue(btn);
			}
			elsif(mode==3)	#FD, LOC or G/S button
			{
				var llocmode = me.lateral_mode.getValue();
				if(btn==0)
				{
					if(llocmode == 3)		# Alrady in LOC mode
					{
						# set target to current magnetic heading
						var tgtHdg = int(me.heading_magnetic.getValue() + 0.50);
						me.hdg_setting.setValue(tgtHdg);
						me.lateral_mode.setValue(2);		# Keep current headding
						me.loc_armed.setValue(0);			# Disarm
					}
					elsif(me.loc_armed.getValue())			# LOC armed but not captured yet
					{
						me.loc_armed.setValue(0);			# Disarm
					}
					else
					{
						me.loc_armed.setValue(1);			# LOC arm
					}
				}
				elsif (btn==1)	#APP button
				{
					var lgsmode = me.vertical_mode.getValue();
					if(lgsmode == 3)	# Already in G/S mode
					{
						me.vertical_mode.setValue(1);	# Keep current altitude
						me.gs_armed.setValue(0);		# Disarm
					}
					elsif(me.gs_armed.getValue())		# G/S armed but not captured yet
					{
						me.gs_armed.setValue(0);		# Disarm
						if(llocmode == 3)		# Alrady in LOC mode
						{
							# set target to current magnetic heading
							var tgtHdg = int(me.heading_magnetic.getValue() + 0.50);
							me.hdg_setting.setValue(tgtHdg);
							me.lateral_mode.setValue(1);		# Keep current headding
							me.loc_armed.setValue(0);			# Disarm
						}
						else
						{
							me.loc_armed.setValue(0);			# Disarm
						}
					}
					else
					{
						me.gs_armed.setValue(1);		# G/S arm
						if(me.loc_armed.getValue() == 0)
						{
							me.loc_armed.setValue(1);		# LOC arm
						}
					}
				}
				elsif(btn == 2)	# FD button toggle
				{
					if(!me.FD.getValue())
					{
						if(me.lateral_mode.getValue() == 0)		# Not set
						{
							# set target to current magnetic heading
							var tgtHdg = int(me.heading_magnetic.getValue() + 0.50);
							me.hdg_setting.setValue(tgtHdg);
							me.lateral_mode.setValue(1);		# HDG HOLD
						}
						if(me.vertical_mode.getValue() == 0)	# Not set
						{
							var alt = int((current_alt+50)/100)*100;
							me.target_alt.setValue(alt);
							me.vertical_mode.setValue(1);		# ALT
						}
						me.FD.setValue(1)
					}
					else
					{
						if(!me.AP.getValue())
						{
							me.lateral_mode.setValue(0);		# Clear
							me.vertical_mode.setValue(0);		# Clear
						}
						me.FD.setValue(0)
					}
				}
			}
#		}
	},
###################
	setAP : func{
		var output = 1-me.AP.getValue();
		var disabled = me.AP_disengaged.getValue();
		if((output==0)and(getprop("position/altitude-agl-ft")<200))
		{
			disabled = 1;
			copilot("Instractor:Autopilot won't engage below 200ft.");
		}
		if((disabled)and(output==0)){output = 1;me.AP.setValue(0);}
		if (output==1)
		{
			var msg="";
			var msg2="";
			var msg3="";
			if (abs(getprop("controls/flight/rudder-trim"))   > 0.04) msg  = "rudder";
			if (abs(getprop("controls/flight/elevator-trim")) > 0.04) msg2 = "pitch";
			if (abs(getprop("controls/flight/aileron-trim"))  > 0.04) msg3 = "aileron";
			if (msg ~ msg2 ~ msg3 != "")
			{
				if ((msg != "")and(msg2!=""))
					msg = msg ~ ", " ~ msg2;
				else
					msg = msg ~ msg2;
				if ((msg != "")and(msg3!=""))
					msg = msg ~ " and " ~ msg3;
				else
					msg = msg ~ msg3;
				copilot("Instracor:Autopilot disengaged. Careful, check " ~ msg ~ " trim!");
			}
			me.loc_armed.setValue(0);			# Disarm
			me.gs_armed.setValue(0);			# Disarm
			if(!me.FD.getValue())
			{
				me.lateral_mode.setValue(0);		# NO MODE
				me.vertical_mode.setValue(0);		# NO MODE
			}
			else
			{
				me.lateral_mode.setValue(1);		# HDG HOLD
				me.vertical_mode.setValue(1);		# ALT
			}
			me.autothrottle_mode.setValue(0);
		}
		else
		{
			if(me.lateral_mode.getValue() == 0)		# Not set
			{
				me.input(0,1);
			}
			if(me.vertical_mode.getValue() == 0)	# Not set
			{
				me.input(1,1);
			}
		}
	},
#################
	ap_update : func
	{
		var current_alt = getprop("instrumentation/altimeter/indicated-altitude-ft");
		var VS = getprop("velocities/vertical-speed-fps");
		var TAS = getprop("velocities/uBody-fps");
		if(me.step == 0)
		{ ### glideslope armed ?###
			if(me.gs_armed.getValue())
			{
				var gsdefl = getprop("instrumentation/nav/gs-needle-deflection");
				var gsrange = getprop("instrumentation/nav/gs-in-range");
				if ((gsdefl< 0.5 and gsdefl>-0.5)and
					gsrange)
				{
					me.vertical_mode.setValue(3);
					me.gs_armed.setValue(0);
				}
			}
		}
		elsif(me.step == 1)
		{ ### localizer armed ? ###
			if(me.loc_armed.getValue())
			{
				if (getprop("instrumentation/nav/in-range"))
				{

					if(!getprop("instrumentation/nav/nav-loc"))
					{
						var vheading = getprop("instrumentation/nav/radials/selected-deg");
						var vvor = getprop("instrumentation/nav/heading-deg");
						var vdist = getprop("instrumentation/nav/nav-distance");
						var vorient = getprop("environment/magnetic-variation-deg");
						var vmag = getprop("orientation/heading-magnetic-deg");
						var vspeed = getprop("/instrumentation/airspeed-indicator/indicated-mach");
						var deg_to_rad = math.pi / 180;
						var vdiff = abs(vheading - vvor + vorient);
						vdiff = abs(vdist * math.sin(vdiff * deg_to_rad));
						var vlim = vspeed / 0.3 * 1300 * abs(vheading - vmag) / 45 ;
						if(vdiff < vlim)
						{
							me.lateral_mode.setValue(3);
							me.loc_armed.setValue(0);
						}
					}
					else
					{
						var hddefl = getprop("instrumentation/nav/heading-needle-deflection");
						if(abs(hddefl) < 9.9)
						{
							me.lateral_mode.setValue(3);
							me.loc_armed.setValue(0);
							var vradials = getprop("instrumentation/nav[0]/radials/target-radial-deg")
								- getprop("environment/magnetic-variation-deg") + 0.5;
							if(vradials < 0.5) vradials += 360;
							elsif(vradials >= 360.5) vradials -= 360;
							me.hdg_setting.setValue(vradials);
						}
					}
				}
			}
			elsif(me.lnav_armed.getValue())
			{
				if(getprop("position/altitude-agl-ft") > 50)
				{
					me.lnav_armed.setValue(0);		# Clear
					me.lateral_mode.setValue(2);	# LNAV
				}
			}
		}
		elsif(me.step == 2)
		{ ### check lateral modes  ###
			var vheading = getprop("orientation/heading-magnetic-deg");
			if(vheading < 0.5)
			{
				vheading += 360;
			}
			me.heading_magnetic.setValue(vheading);
			var idx = me.lateral_mode.getValue();
			me.AP_roll_mode.setValue(me.roll_list[idx]);
			me.AP_roll_engaged.setBoolValue(idx > 0);
		}
		elsif(me.step == 3)
		{ ### check vertical modes  ###
			var idx = me.vertical_mode.getValue();
			var offset = (abs(me.vs_ind.getValue()) / 8);
			if(offset < 20)
			{
				offset = 20;
			}
			if((idx==1)or(idx==2))
			{
				if (abs(current_alt - me.alt_setting.getValue()) < offset)
				{
					# within MCP altitude: switch to ALT HOLD mode
					idx = 1;	# ALT
#					if(me.autothrottle_mode.getValue() != 0)
#					{
#						me.autothrottle_mode.setValue(5);	# A/T SPD
#					}
					me.vs_setting.setValue(0);
				}
			}
			me.vertical_mode.setValue(idx);
			me.AP_pitch_mode.setValue(me.pitch_list[idx]);
		}
		elsif(me.step == 4) 			### Auto Throttle mode control  ###
		{
			# Auto throttle arm switch is offed
			if(me.at1.getValue() == 0)
			{
				me.autothrottle_mode.setValue(0);
			}
			# AP and A/T off when below AGL100ft
			elsif(getprop("position/altitude-agl-ft") < 100)
			{
				me.autothrottle_mode.setValue(0);
				me.AP.setValue(0);
			}
			# Take off mode and above baro 400 ft
			elsif(getprop("position/altitude-agl-ft") > 400)
			{
				if(me.at1.getValue() == 1)
				{
					me.autothrottle_mode.setValue(1);
				}
			}
			idx = me.autothrottle_mode.getValue();
			me.AP_speed_mode.setValue(me.spd_list[idx]);
		}
		elsif(me.step == 5)
		{
			if (getprop("/autopilot/route-manager/active")){
				var max_wpt = getprop("/autopilot/route-manager/route/num");
				var atm_wpt = getprop("/autopilot/route-manager/current-wp");
				var destination_elevation = getprop("/autopilot/route-manager/destination/field-elevation-ft");
				var total_distance = getprop("/autopilot/route-manager/total-distance");
				if(me.lateral_mode.getValue() == 2)		# Current mode is LNAV
				{
					if(atm_wpt < (max_wpt - 1))
					{
						me.remaining_distance.setValue(getprop("/autopilot/route-manager/wp/remaining-distance-nm")
							+ getprop("autopilot/route-manager/wp/dist"));
						var next_course = getprop("/autopilot/route-manager/wp[1]/bearing-deg");
					}
					else
					{
						me.remaining_distance.setValue(getprop("autopilot/route-manager/wp/dist"));
					}
				}
				if(getprop("/autopilot/route-manager/active"))
				{
					var wpt_distance = getprop("autopilot/route-manager/wp/dist");
					var groundspeed = getprop("/velocities/groundspeed-kt");
					if(wpt_distance != nil)
					{
						var wpt_eta = (wpt_distance / groundspeed * 3600);
						var gmt = getprop("instrumentation/clock/indicated-sec");
						if((getprop("gear/gear[1]/wow") == 0) and (getprop("gear/gear[2]/wow") == 0))
						{
							gmt += (wpt_eta + 30);
							var gmt_hour = int(gmt / 3600);
							if(gmt_hour > 24)
							{
								gmt_hour -= 24;
								gmt -= 24 * 3600;
							}
							me.estimated_time_arrival.setValue(gmt_hour * 100 + int((gmt - gmt_hour * 3600) / 60));
							var change_wp = abs(getprop("/autopilot/route-manager/wp[1]/bearing-deg") - me.heading_magnetic.getValue());
							if(change_wp > 180) change_wp = (360 - change_wp);
							if(((me.heading_change_rate * change_wp) > wpt_eta)
								or (wpt_distance < 0.4)
								or ((me.remaining_distance_log_last < wpt_distance) and (change_wp < 80)))
 	 						{
 	 							if(atm_wpt < (max_wpt - 1))
								{
									atm_wpt += 1;
									props.globals.getNode("/autopilot/route-manager/current-wp").setValue(atm_wpt);
									me.altitude_restriction = getprop("/autopilot/route-manager/route/wp["~atm_wpt~"]/altitude-ft");
								}
								me.remaining_distance_log_last = 36000;
							}
							else
							{
								me.remaining_distance_log_last = wpt_distance;
							}
						}
						if(getprop("/autopilot/internal/waypoint-bearing-error-deg") != nil)
						{
							if(abs(getprop("/position/latitude-deg")) < 80)
							{
	 							if(abs(getprop("/instrumentation/gps/wp/wp[1]/course-error-nm")) < 2)
								{
									setprop("/autopilot/internal/course-deviation", getprop("/instrumentation/gps/wp/wp[1]/course-error-nm"))
								}
								elsif(getprop("/instrumentation/gps/wp/wp[1]/course-deviation-deg") < 2)
								{
									setprop("/autopilot/internal/course-deviation", getprop("/instrumentation/gps/wp/wp[1]/course-deviation-deg"))
								}
								else
								{
									setprop("/autopilot/internal/course-deviation", 0);
								}
							}
							else
							{
								setprop("/autopilot/internal/course-deviation", 0);
							}
						}
					}
				}
			}
		}
		me.step+=1;
		if(me.step > 5) me.step = 0;
	},
};

#####################
var click_reset = func(propName) {
    setprop(propName,0);
}

controls.click = func(button) {
    if (getprop("sim/freeze/replay-state"))
        return;
    var propName="sim/sound/click"~button;
    setprop(propName,1);
    settimer(func { click_reset(propName) },0.4);
}

var afds = AFDS.new();

var afds_init_listener = setlistener("/sim/signals/fdm-initialized", func {
	removelistener(afds_init_listener);
	settimer(update_afds,6);
	print("AFDS System ... check");
});

var update_afds = func {
	afds.ap_update();
	settimer(update_afds, 0);
}
