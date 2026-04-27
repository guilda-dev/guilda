net = network.IEEE14bus;

ev1 = odeEventSet("ev1", net, "FaultBus", "B001", "TimeSpan", [3,3.01]);

sol = net.simulate([0,50], ev1);

xsol = sol.odeResults;

plot(xsol.t, [xsol.Bus{1}.X{1}.omega, xsol.Bus{2}.X{1}.omega, xsol.Bus{3}.X{1}.omega, xsol.Bus{6}.X{1}.omega, xsol.Bus{8}.X{1}.omega])


