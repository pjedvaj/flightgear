### Universal fuel transfer system by Tomaskom ###

#Script for automated fuel transfer from fuel tanks to Engine feed tank based on fuel tank priority. Gathers fuel from fuel tanks within a priority group that have most fuel first - results in equalized fuel levels within the group. Also manages enabling all tanks when refueling. 

#Fuel tanks priority: fist empty droptanks (4,3), then wingtip fixed tanks (2) and fuselage tanks are last (1). 

var fuel_node = props.globals.getNode("/consumables/fuel");

var engFeedN = 0; #number of tank which serves as engine feed

var interval = 0.1; #approximate transfer cycle interval
var galsPerSec = 1.5; #fuel flow to engine feed tank (gal_us/sec)

#delta times for exact flow rates
var lastTime = getprop("/sim/time/elapsed-sec");

#property for ground refueling
var refuel_galsPerSec = 0;

#class representing a fuel tank
var fuelTank = {
	#constructor
	new: func(tankN, prio = 0) {
		var m = { parents: [fuelTank] };
		m.tankNum = tankN;
		m.priority = prio;
		m.dump = 0;
		return m;
	},
	#get fuel tank emptying priority
	getPriority: func {
		return me.priority;
	},
	#get fuel level
	getLevel: func {
		return getprop("/consumables/fuel/tank["~me.tankNum~"]/level-gal_us");
	},
	#get fuel capacity
	getCapacity: func {
		return getprop("/consumables/fuel/tank["~me.tankNum~"]/capacity-gal_us");
	},
	#get requested ammount of fuel or all remaining fuel if less than requested
	takeFuel: func(fuel_req) {
		var fuel_level = getprop("/consumables/fuel/tank["~me.tankNum~"]/level-gal_us");
		if(fuel_level<fuel_req) {
			setprop("/consumables/fuel/tank["~me.tankNum~"]/level-gal_us", 0);
			return fuel_level;
		}
		else {
			setprop("/consumables/fuel/tank["~me.tankNum~"]/level-gal_us", fuel_level-fuel_req);
			return fuel_req;
		}
	},
	#pump requested ammount of fuel in this tank, returns overflow if any
	pushFuel: func(fuel_push) {
		var fuel_level = getprop("/consumables/fuel/tank["~me.tankNum~"]/level-gal_us");
		var fuel_capacity = getprop("/consumables/fuel/tank["~me.tankNum~"]/capacity-gal_us");
		if((fuel_level+fuel_push)>fuel_capacity) {
			setprop("/consumables/fuel/tank["~me.tankNum~"]/level-gal_us", fuel_capacity);
			return fuel_level+fuel_push-fuel_capacity;
		}
		else {
			setprop("/consumables/fuel/tank["~me.tankNum~"]/level-gal_us", fuel_level+fuel_push);
			return 0;
		}
	},
	#get enabled status
	getEnable: func {
		return getprop("/consumables/fuel/tank["~me.tankNum~"]/selected");
	},
	#set enabled status
	setEnable: func(enable) {
		setprop("/consumables/fuel/tank["~me.tankNum~"]/selected", enable);
	},
	#set amount of fuel (gal) to be dumped per sec
	fuelDump: func(dumpAmmount) {
		me.dump = dumpAmmount;
	},
	#perform dump, to be called during main loop
	performDump: func(dt) {
		if(me.dump > 0) {
			me.takeFuel(dt*me.dump);
		}
	},
};

var engineFeedTank = fuelTank.new(engFeedN, 0); 

#keep Engine feed tank enabled, TODO: change when engine startup procedures are implemented
engFeedEnable = func {
	if(engineFeedTank.getEnable() == 0 and engineFeedTank.getLevel() > 0) {
		engineFeedTank.setEnable(1);
	}
	else {
		if(engineFeedTank.getEnable() == 1 and engineFeedTank.getLevel() == 0) {
			engineFeedTank.setEnable(0);
		}
	}
}
setlistener("/consumables/fuel/tank["~engFeedN~"]/selected", engFeedEnable);

var tanks = [
	#fuselage tanks
	fuelTank.new(1, 1),
	fuelTank.new(2, 1),
	fuelTank.new(3, 1),
	fuelTank.new(4, 1),
	fuelTank.new(5, 1),
	#wingtip tanks
	fuelTank.new(6, 2),
	fuelTank.new(7, 2),
	#inner droptanks
	fuelTank.new(8, 3),
	fuelTank.new(9, 3),
	#outer droptanks
	fuelTank.new(10, 4),
	fuelTank.new(11, 4),
];

var doRefuel = func(dt) {
	if( getprop("/gear/gear[0]/wow") 
	and getprop("/gear/gear[1]/wow") 
	and getprop("/gear/gear[2]/wow") 
	and (getprop("/velocities/groundspeed-kt") < 2) ) {
		#determine fuel to be allocated in this cycle
		var refuelAmmount = refuel_galsPerSec * dt;
		
		var maxPrio = 0;
		foreach(var tank; tanks) {
			if(tank.getPriority() > maxPrio) maxPrio = tank.getPriority();
		}

		for(var iPrioGroup=0; iPrioGroup<=maxPrio; iPrioGroup+=1) {
			var thisGroup = []; #print("refueling group "~iPrioGroup);
			forindex(var iTank; tanks) {
				if(tanks[iTank].getPriority() == iPrioGroup) {
					append(thisGroup, {index:iTank, fuelLevel:tanks[iTank].getLevel()});
					#print("appending tank "~iTank~" (prio="~iPrioGroup~")");
				}
			}
			if(size(thisGroup) == 0) continue;
			
			#get previous array sorted - descending order
			var sortedGroup = sort(thisGroup, 
				func(h1, h2){return h1.fuelLevel-h2.fuelLevel;} );
			
			#try to push remaining available fuel and save overflow for next tanks
			foreach(var iSorted; sortedGroup) {
				#print("prerefuelAmmount: "~refuelAmmount);
				refuelAmmount = tanks[iSorted.index].pushFuel(refuelAmmount);
				#print("refuelAmmount:    "~refuelAmmount);
			}
		}
		
		if(refuelAmmount > 0) {
			screen.log.write("Refueling finished, all mounted tanks are full. ", 1, 0.6, 0.1);
			refuel_galsPerSec = 0;
		}
	}
	else {
		refuel_galsPerSec = 0;
		screen.log.write("You must be stopped on the ground for refueling!", 1, 0.6, 0.1);
	}
}

#function to be used externally to engage ground refuel - parameter sets flow in US gallons per second
var refuel = func(fuelGalsPerSec) {
	if(fuelGalsPerSec>0) {
		refuel_galsPerSec = fuelGalsPerSec;
	}
	else {
		refuel_galsPerSec = 0;
	}
}

#cycle:
#check how much fuel is missing in the Engine feed tank
#check which highest priority still has fuel
#get remaining fuel levels of those tanks
#request balanced ammount of fuel from each tank (to keep levels equal)
#store the fuel to the Engine feed tank
var fuelTransfer = func {
	#get delta time
	var nowTime = getprop("/sim/time/elapsed-sec");
	
	var simSpeed = getprop("/sim/speed-up");
	var dTime = (nowTime - lastTime) * simSpeed;
	if(dTime < 0) dTime = 0;
	
	#try ground refuel
	if(refuel_galsPerSec > 0) doRefuel(dTime);
	
	var cycleAmmount = galsPerSec * dTime;

	#check how much fuel is missing in the Engine feed tank
	var missingFuel = engineFeedTank.getCapacity() - engineFeedTank.getLevel();
		
	var fuelToGet = (cycleAmmount < missingFuel ? cycleAmmount : missingFuel);
	
	#check which highest priority still has fuel (and perform dump if tank is set to do it)
	var maxNonemptyPrio = 0;
	forindex(var i; tanks) {
		tanks[i].performDump(dTime);
		if( tanks[i].getLevel() > 0 and tanks[i].getPriority() > maxNonemptyPrio ) {
			maxNonemptyPrio = tanks[i].getPriority();
		}
	}
	
	#create array of hashes, each hash contains index (from tanks[]), fuel level and fuel to be requested
	var activeTanks = [];
	forindex(var i; tanks) {
		if( tanks[i].getPriority() == maxNonemptyPrio ) {
			append(activeTanks, {index:i, fuelLevel:tanks[i].getLevel(), reqFuel:0});
		}
	}
	
	#skip loop if no tanks (eg. when not yet initialized on startup)
	if(size(activeTanks) == 0) {
		settimer(fuelTransfer, interval);
		lastTime = nowTime;
		return;
	}
	
	#get previous array sorted - descending order
	var sortedTanks = sort(activeTanks, 
		func(h1, h2){return h2.fuelLevel-h1.fuelLevel;} );
	
	#debug check for correct sorting
	#forindex(var i; sortedTanks) {
	#	print("Sorted tank " ~ sortedTanks[i].index ~ ", fuel level: " ~ sortedTanks[i].fuelLevel);
	#}
	
	var numTanks = size(sortedTanks);
	
	var gatheredFuel = 0;
	var cont = 1; #continue looping?
	var stopIndex = -1; #index where looping stopped
	for(var i = 0; cont; i+=1) {
		if( (i+1) < numTanks and (gatheredFuel + (sortedTanks[i].fuelLevel - sortedTanks[i+1].fuelLevel) * (i+1)) < fuelToGet ) {
			gatheredFuel += (sortedTanks[i].fuelLevel - sortedTanks[i+1].fuelLevel) * (i+1);
		}
		else {
			stopIndex = i;
			cont = 0;
		}
	}
	
	var toGather = fuelToGet - gatheredFuel;
	var leastReducedLevel = sortedTanks[stopIndex].fuelLevel; #level of tank with least fuel which still gets used
	
	#set required fuel
	for(var i = 0; i < stopIndex; i+=1) {
		sortedTanks[i].reqFuel += sortedTanks[i].fuelLevel - leastReducedLevel;
	}
	
	for(var i = 0; i <= stopIndex; i+=1) {
		sortedTanks[i].reqFuel += toGather/(stopIndex+1);
	}
	
	#debug check for correct reqFuel
	#forindex(var i; sortedTanks) {
	#	print("Tank " ~ sortedTanks[i].index ~ ", fuel level: " ~ sortedTanks[i].fuelLevel);
	#	print("Requesting fuel: " ~ sortedTanks[i].reqFuel);
	#}
	
	#execute fuel transfer
	var transferedFuel = 0;
	forindex(var i; sortedTanks) {
		transferedFuel += tanks[sortedTanks[i].index].takeFuel(sortedTanks[i].reqFuel);
	}
	engineFeedTank.pushFuel(transferedFuel);
	
	lastTime = nowTime;
	
	settimer(fuelTransfer, interval/simSpeed);
}
fuelTransfer();


#Air-to-Air refueling and tank enable control - all tanks temporarily enabled when receiving fuel and disabled otherwise (except for Engine feed tank)
aarHandle = func {
	if(getprop("/systems/refuel/contact")) {
		foreach (var tank; tanks) {
			tank.setEnable(1);
		}
	}
	else {
		foreach (var tank; tanks) {
			tank.setEnable(0);
		}
	}
}
#set listener on the aar contact property
setlistener("/systems/refuel/contact", aarHandle, 1, 0);
#set listeners on all tanks enable property to counter manual changes
foreach (var tank; tanks) {
	setlistener("/consumables/fuel/tank["~tank.tankNum~"]/selected", aarHandle, 1, 0);
}


print("ALCA fuel system initialized");