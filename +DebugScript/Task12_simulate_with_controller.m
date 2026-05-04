net = network.IEEE14bus;


avr = controller.AVR_DC1("avr");
pss = controller.PSS1("pss");

net.a_Bus{1}.a_Component{1}.add_local_controller(avr,pss)

net.initialize;

ev1 = odeEventSet("ev1", net, "FaultBus", "B001", "TimeSpan", [3,3.06]);

sol = net.simulate([0,50], ev1);

xsol = sol.odeResults;

plot(xsol.t, [xsol.Bus{1}.X{1}.omega, xsol.Bus{2}.X{1}.omega, xsol.Bus{3}.X{1}.omega, xsol.Bus{6}.X{1}.omega, xsol.Bus{8}.X{1}.omega])