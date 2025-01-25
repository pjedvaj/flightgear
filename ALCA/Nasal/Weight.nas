#weight check
var maxWeight = 17637; #8000kg in lb
var alreadyOverweight = 0;
var weightCheck = func {
	currentWeight = getprop("/yasim/gross-weight-lbs");
	if(currentWeight == nil)
		return;
	
	if( currentWeight > maxWeight ) {
		if( alreadyOverweight == 0 ) {
			screen.log.write("Aircraft is overweight!");
			screen.log.write("Max: "~maxWeight~"lb, Current: "~int(currentWeight)~"lb");
			alreadyOverweight = 1;
		}
	}
	else alreadyOverweight = 0;
	
}