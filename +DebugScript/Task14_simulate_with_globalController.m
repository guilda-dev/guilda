ev = odeEventSet("ev", net, "TimeSpan", [5,50], "InputUnit", "LPQ1B005", "InputValue", 0.1, "InputName", "Pload");

sol = net.simulate([0,50], ev);

xsol = sol.odeResults;

plot(xsol.t, [xsol.Bus{1}.X{1}.omega, xsol.Bus{2}.X{1}.omega, xsol.Bus{3}.X{1}.omega, xsol.Bus{6}.X{1}.omega, xsol.Bus{8}.X{1}.omega])