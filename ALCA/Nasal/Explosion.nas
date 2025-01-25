props.globals.initNode("/disintegration/explosion/explode", 0, "BOOL");
props.globals.initNode("/disintegration/explosion/exploded", 0, "BOOL");
props.globals.initNode("/disintegration/explosion/fire", 0, "BOOL");

#flame Rembrandt light brightness alternation
var flamePath = "/disintegration/explosion/";
props.globals.initNode(flamePath ~ "flameBright", 0.0, "DOUBLE");
var flameSeq = [0,0,0,0];
var curSeq = 0;
var flameBright = func {
	flameSeq[curSeq] = 0.5 + rand()*0.5;

	interpolate(flamePath ~ "flameBright", (flameSeq[0]+flameSeq[1]+flameSeq[2]+flameSeq[3]) / 4, 0.02);
	
	if( curSeq < 3)
		curSeq += 1;
	else
		curSeq = 0;
}
var flameBrightExplode = func {
	flameSeq = [2.5,2.5,2.5,2.5];
	interpolate(flamePath ~ "flameBright", 2.5, 0);
}
var flameBrightLoop = maketimer(0.02, flameBright);

#detonation with fire
var explode = func(fire) {
	setprop("/disintegration/explosion/explode", 1);
	setprop("/disintegration/explosion/exploded", 1);
	if(fire) {
		setprop("/disintegration/explosion/fire", 1);
	}
	settimer( func {setprop("/disintegration/explosion/explode", 0);} , 0.2);
	flameBrightExplode();
	flameBrightLoop.start();
}

var stopFire = func {
	setprop("/disintegration/explosion/fire", 0);
	setprop("/disintegration/explosion/exploded", 0);
	flameBrightLoop.stop();
}
