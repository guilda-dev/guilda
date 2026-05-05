net = network.IEEE14bus;

c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};

Gcon = controller.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);

net.add_global_controller(Gcon);

net.initialize;

ev = odeEventSet("ev", net, "TimeSpan", [5,50], "InputUnit", "LPQ1B005", "InputValue", 0.1, "InputName", "Pload");

sol = net.simulate([0,50], ev);

xsol = sol.odeResults;

plot(xsol.t, [xsol.Bus{1}.X{1}.omega, xsol.Bus{2}.X{1}.omega, xsol.Bus{3}.X{1}.omega, xsol.Bus{6}.X{1}.omega, xsol.Bus{8}.X{1}.omega])