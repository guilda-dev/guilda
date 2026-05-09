
net = network.IEEE14bus;

o = cell(5,1);
o{1} = odeEventSet("ev1", net, "TimeSpan",        3, "OffsetState", "delta", "OffsetUnit", "SG1B001", "OffsetValue", pi/6);
o{2} = odeEventSet("ev2", net, "TimeSpan", [ 8,10.5], "InputUnit", "SG1B002", "InputName", ["Pmech";"Vfield"], "InputValue", {0.7; @(t)sqrt(t)*0.1+1});
o{3} = odeEventSet("ev3", net, "TimeSpan", [14,15.0], "InputUnit", "LPQ2B002", "InputName", ["Pload";"Qload"], "InputValue", {@(t) 0.1*t^2-0.2*t+1; @(t) 0.1*sqrt(t)*0.1});
o{4} = odeEventSet("ev4", net, "TimeSpan", [ 8,8.02], "FaultBus", "B008");
o{5} = odeEventSet("ev5", net, "TimeSpan", [ 9,11.0], "TripUnit", "LPQ2B003");

sol = net.simulate([0,50], o{:});

xsol = sol.odeResults;
figure
hold on
arrayfun(@(i) plot(xsol.t, xsol.Bus(i).Component(1).X.omega), [1,2,3,6,8]);