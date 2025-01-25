var lpfilter = aircraft.lowpass.new(1); #raise this to filter more

blackout = func {
    GCurrent = getprop("/accelerations/pilot-g[0]");
    
    if (GCurrent == nil) { GCurrent = 1.0; }
    lpfilter.filter(GCurrent);

    if (lpfilter.get() > 6) #minimum value to black out
    {
        setprop("/sim/rendering/redout/red",0);
        setprop("/sim/rendering/redout/alpha",(lpfilter.get()-6)/4);
    }
    elsif (lpfilter.get() < -1)  #minimum to redout
    {
        setprop("/sim/rendering/redout/red",1);
        setprop("/sim/rendering/redout/alpha",(lpfilter.get()+1)/-7);
    }
    else 
    {
        setprop("/sim/rendering/redout/alpha",0);
    }
}

setlistener("/accelerations/pilot-g", blackout);
