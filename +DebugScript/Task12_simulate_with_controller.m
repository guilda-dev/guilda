ev1 = odeEventSet("ev1", net, "FaultBus", "B008", "TimeSpan", [3,3.5]);

sol = net.simulate([0,50], ev1);

xsol = sol.odeResults;

figure
hold on
arrayfun(@(i) plot(xsol.t, xsol.Bus(i).Component(1).X.omega), [1,2,3,6,8]);