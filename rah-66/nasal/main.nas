#  RAH-66, based on OH-1.nas

if (!contains(globals, "cprint")) {
	globals.cprint = func {};
}

var optarg = aircraft.optarg;
var makeNode = aircraft.makeNode;

var sin = func(a) { math.sin(a * math.pi / 180.0) }
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var pow = func(v, w) { math.exp(math.ln(v) * w) }
var npow = func(v, w) { math.exp(math.ln(abs(v)) * w) * (v < 0 ? -1 : 1) }
var clamp = func(v, min = 0, max = 1) { v < min ? min : v > max ? max : v }
var normatan = func(x) { math.atan2(x, 1) * 2 / math.pi }


# timers ============================================================
var turbine_timer = aircraft.timer.new("/sim/time/hobbs/turbines", 10);
aircraft.timer.new("/sim/time/hobbs/helicopter", nil).start();


# engines/rotor =====================================================
var state = props.globals.getNode("sim/model/rah-66/state");
var rotor = props.globals.getNode("controls/engines/engine/magnetos");
var rotor_rpm = props.globals.getNode("rotors/main/rpm");
var torque = props.globals.getNode("rotors/gear/total-torque", 1);
var collective = props.globals.getNode("controls/engines/engine[0]/throttle");
var turbine = props.globals.getNode("sim/model/rah-66/turbine-rpm-pct", 1);
var torque_pct = props.globals.getNode("sim/model/rah-66/torque-pct", 1);
var stall = props.globals.getNode("rotors/main/stall", 1);
var stall_filtered = props.globals.getNode("rotors/main/stall-filtered", 1);
var view_number = props.globals.getNode("sim/current-view/view-number", 1);
var inside_volume = props.globals.getNode("sim/model/rah-66/inside_volume", 1);
var outside_volume = props.globals.getNode("sim/model/rah-66/outside_volume", 1);


# 0 off
# 1 startup sound in progress
# 2 sound loop
# 3 shutdown sound in progress

var engines = func {
	crashed and return;
	var s = state.getValue();
	if (arg[0] == 1) {
		if (s == 0) {
			turbine_timer.start();
			state.setValue(1);				# engines started
			settimer(func { rotor.setValue(1) }, 3);
			interpolate(turbine, 100, 25);
			settimer(func { state.setValue(2) }, 51);	# -> engines running
		}
	} else {
		if (s == 2) {
			turbine_timer.stop();
			rotor.setValue(0);				# engines stopped
			state.setValue(3);
			interpolate(turbine, 0, 30);
			settimer(func { state.setValue(0) }, 71);	# -> engines off
		}
	}
}


# torquemeter
var torque_val = 0;
torque.setDoubleValue(0);

var update_torque = func(dt) {
	var f = dt / (0.2 + dt);
	torque_val = torque.getValue() * f + torque_val * (1 - f);
	torque_pct.setDoubleValue(torque_val / 5300);
}


# sound =============================================================

# stall sound
var stall_val = 0;
stall.setDoubleValue(0);

var update_stall = func(dt) {
	var s = stall.getValue();
	if (s < stall_val) {
		var f = dt / (0.3 + dt);
		stall_val = s * f + stall_val * (1 - f);
	} else {
		stall_val = s;
	}
	var c = collective.getValue();
	stall_filtered.setDoubleValue(stall_val + 0.006 * (1 - c));
}


# skid slide sound
var Skid = {
	new : func(n) {
		var m = { parents : [Skid] };
		var soundN = props.globals.getNode("sim/sound", 1).getChild("slide", n, 1);
		var gearN = props.globals.getNode("gear", 1).getChild("gear", n, 1);

		m.compressionN = gearN.getNode("compression-norm", 1);
		m.rollspeedN = gearN.getNode("rollspeed-ms", 1);
		m.frictionN = gearN.getNode("ground-friction-factor", 1);
		m.wowN = gearN.getNode("wow", 1);
		m.volumeN = soundN.getNode("volume", 1);
		m.pitchN = soundN.getNode("pitch", 1);

		m.compressionN.setDoubleValue(0);
		m.rollspeedN.setDoubleValue(0);
		m.frictionN.setDoubleValue(0);
		m.volumeN.setDoubleValue(0);
		m.pitchN.setDoubleValue(0);
		m.wowN.setBoolValue(1);
		m.self = n;
		return m;
	},
	update : func {
		me.wowN.getBoolValue() or return;
		var rollspeed = abs(me.rollspeedN.getValue());
		me.pitchN.setDoubleValue(rollspeed * 0.6);

		var s = normatan(20 * rollspeed);
		var f = clamp((me.frictionN.getValue() - 0.5) * 2);
		var c = clamp(me.compressionN.getValue() * 2);
		me.volumeN.setDoubleValue(s * f * c * 2);
		#if (!me.self) {
		#	cprint("33;1", sprintf("S=%0.3f  F=%0.3f  C=%0.3f  >>  %0.3f", s, f, c, s * f * c));
		#}
	},
};

var skid = [];
for (var i = 0; i < 4; i += 1) {
	append(skid, Skid.new(i));
}

var update_slide = func {
	forindex (var i; skid) {
		skid[i].update();
	}
}


# skid slide sound
var Skid = {
	new : func(n) {
		var m = { parents : [Skid] };
		var soundN = props.globals.getNode("sim/sound", 1).getChild("slide", n, 1);
		var gearN = props.globals.getNode("gear", 1).getChild("gear", n, 1);

		m.compressionN = gearN.getNode("compression-norm", 1);
		m.rollspeedN = gearN.getNode("rollspeed-ms", 1);
		m.frictionN = gearN.getNode("ground-friction-factor", 1);
		m.wowN = gearN.getNode("wow", 1);
		m.volumeN = soundN.getNode("volume", 1);
		m.pitchN = soundN.getNode("pitch", 1);

		m.compressionN.setDoubleValue(0);
		m.rollspeedN.setDoubleValue(0);
		m.frictionN.setDoubleValue(0);
		m.volumeN.setDoubleValue(0);
		m.pitchN.setDoubleValue(0);
		m.wowN.setBoolValue(1);
		m.self = n;
		return m;
	},
	update : func {
		me.wowN.getBoolValue() or return;
		var rollspeed = abs(me.rollspeedN.getValue());
		me.pitchN.setDoubleValue(rollspeed * 0.6);

		var s = normatan(20 * rollspeed);
		var f = clamp((me.frictionN.getValue() - 0.5) * 2);
		var c = clamp(me.compressionN.getValue() * 2);
		me.volumeN.setDoubleValue(s * f * c * 2);
		#if (!me.self) {
		#	cprint("33;1", sprintf("S=%0.3f  F=%0.3f  C=%0.3f  >>  %0.3f", s, f, c, s * f * c));
		#}
	},
};

var skid = [];
for (var i = 0; i < 3; i += 1) {
	append(skid, Skid.new(i));
}

var update_slide = func {
	forindex (var i; skid) {
		skid[i].update();
	}
}


# "manual" rotor animation for flight data recorder replay ============
var rotor_step = props.globals.getNode("sim/model/rah-66/rotor-step-deg");
var blade1_pos = props.globals.getNode("rotors/main/blade[0]/position-deg", 1);
var blade2_pos = props.globals.getNode("rotors/main/blade[1]/position-deg", 1);
var blade3_pos = props.globals.getNode("rotors/main/blade[2]/position-deg", 1);
var blade4_pos = props.globals.getNode("rotors/main/blade[3]/position-deg", 1);
var blade5_pos = props.globals.getNode("rotors/main/blade[4]/position-deg", 1);
var rotorangle = 0;

var rotoranim_loop = func {
	i = rotor_step.getValue();
	if (i >= 0.0) {
		blade1_pos.setValue(rotorangle);
		blade2_pos.setValue(rotorangle + 72);
		blade3_pos.setValue(rotorangle + 144);
		blade4_pos.setValue(rotorangle + 216);
		blade5_pos.setValue(rotorangle + 288);
		rotorangle += i;
		settimer(rotoranim_loop, 0.1);
	}
}

var init_rotoranim = func {
	if (rotor_step.getValue() >= 0.0) {
		settimer(rotoranim_loop, 0.1);
	}
}


# view management ===================================================

var elapsedN = props.globals.getNode("/sim/time/elapsed-sec", 1);
var flap_mode = 0;
var down_time = 0;
controls.flapsDown = func(v) {
	if (!flap_mode) {
		if (v < 0) {
			down_time = elapsedN.getValue();
			flap_mode = 1;
			dynamic_view.lookat(
					5,     # heading left
					-20,   # pitch up
					0,     # roll right
					0.2,   # right
					0.6,   # up
					0.85,  # back
					0.2,   # time
					55,    # field of view
			);
		} elsif (v > 0) {
			flap_mode = 2;
			var p = "/sim/view/dynamic/enabled";
			setprop(p, !getprop(p));
		}

	} else {
		if (flap_mode == 1) {
			if (elapsedN.getValue() < down_time + 0.2) {
				return;
			}
			dynamic_view.resume();
		}
		flap_mode = 0;
	}
}


# register function that may set me.heading_offset, me.pitch_offset, me.roll_offset,
# me.x_offset, me.y_offset, me.z_offset, and me.fov_offset
#
dynamic_view.register(func {
	var lowspeed = 1 - normatan(me.speedN.getValue() / 50);
	var r = sin(me.roll) * cos(me.pitch);

	me.heading_offset =						# heading change due to
		(me.roll < 0 ? -50 : -30) * r * abs(r);			#    roll left/right

	me.pitch_offset =						# pitch change due to
		(me.pitch < 0 ? -50 : -50) * sin(me.pitch) * lowspeed	#    pitch down/up
		+ 15 * sin(me.roll) * sin(me.roll);			#    roll

	me.roll_offset =						# roll change due to
		-15 * r * lowspeed;					#    roll
});


# main() ============================================================
var delta_time = props.globals.getNode("/sim/time/delta-realtime-sec", 1);
var adf_rotation = props.globals.getNode("/instrumentation/adf/rotation-deg", 1);
var hi_heading = props.globals.getNode("/instrumentation/heading-indicator/indicated-heading-deg", 1);

var main_loop = func {
	adf_rotation.setDoubleValue(hi_heading.getValue());

	var dt = delta_time.getValue();
	update_torque(dt);
	update_stall(dt);
	update_slide();
	if ( view_number.getValue() == 0) {
		inside_volume.setDoubleValue(1.0);
		outside_volume.setDoubleValue(0.0);
	} else {
		inside_volume.setDoubleValue(0.0);
		outside_volume.setDoubleValue(1.0);
	}
	settimer(main_loop, 0);
}


var crashed = 0;
var variant = nil;
var config_dialog = nil;

# initialization
setlistener("/sim/signals/fdm-initialized", func {

	init_rotoranim();
	collective.setDoubleValue(1);

	setlistener("/sim/signals/reinit", func(n) {
		n.getBoolValue() and return;
		cprint("32;1", "reinit");
		turbine_timer.stop();
		collective.setDoubleValue(1);
		variant.scan();
		crashed = 0;
	});

	setlistener("sim/crashed", func(n) {
		cprint("31;1", "crashed ", n.getValue());
		turbine_timer.stop();
		if (n.getBoolValue()) {
			crash(crashed = 1);
		}
	});

	setlistener("/sim/freeze/replay-state", func(n) {
		cprint("33;1", n.getValue() ? "replay" : "pause");
		if (crashed) {
			crash(!n.getBoolValue())
		}
	});

	# the attitude indicator needs pressure
	 settimer(func { setprop("engines/engine/rpm", 3000) }, 8);

	main_loop();
});