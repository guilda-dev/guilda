net = network.IEEE14bus;

o = cell(5,1);
o{1} = odeEventSet("ev1", net, "TimeSpan", 5, "OffsetState", "delta", "OffsetUnit", "SG1B001", "OffsetValue", pi/6);
o{2} = odeEventSet("ev2", net, "TimeSpan", 7, "InputUnit", "SG1B002", "InputName", ["Pmech";"Vfield"], "InputValue", {1.2; @(t,x)t^4+2});
o{3} = odeEventSet("ev3", net, "TimeSpan", 8, "InputUnit", "LPQ2B002", "InputName", ["Pload";"Qload"], "InputValue", {@(t,x) t^2-t+1; @(t,x) t^7});
o{4} = odeEventSet("ev4", net, "TimeSpan", [8,8.01], "FaultBus", "B001");
o{5} = odeEventSet("ev5", net, "TimeSpan", [8,8.02], "TripUnit", "SG1B003");

table(o{:})

setEventCondition(o{:}, "Iteration",1,"TimePhase",[0,5])

getInitialCondition(o{:})

getNextPhase(o{:})