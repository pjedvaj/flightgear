#MP payload transfer via string by Tomaskom

var stringIndex = 0; #index of sim/multiplay/generic/string[i] which is used for transfer
var intProp = "payload-int"; #expects existence of this property carrying int identifier of the payload option in every /sim/weight[i]/ - set this according to your payload management script

var weightsNode = props.globals.getNode("/sim");


var transmitString = func {
	var string = "";
	var failed = 0;
	forindex(var i; weightsNode.getChildren("weight")) {
		value = getprop("/sim/weight["~i~"]/"~intProp);
		if(value==nil) {
			value = 0;
			failed = 1;
		}
		string = string~(string==""?"":",")~int(value);
	}
	if(failed) settimer(transmitString, 1);
	setprop("sim/multiplay/generic/string["~stringIndex~"]", string);
	#print(string);
}

forindex(var i; weightsNode.getChildren("weight")) {
	setlistener("/sim/weight["~i~"]/"~intProp, transmitString);
}
transmitString();

print("MpEncode system initialized");
