ev = odeEventSet("ev", net, "TimeSpan", [5,50], "InputUnit", "LPQ1B005", "InputValue", 0.1, "InputName", "Pload");

sol = net.simulate([0,50], ev);

xsol = sol.odeResults;

figure
hold on
arrayfun(@(i) plot(xsol.t, xsol.Bus(i).Component(1).X.omega), [1,2,3,6,8]);