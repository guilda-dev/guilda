net = network.IEEE14bus;

ev1 = odeEventSet("ev1", net, "FaultBus", "B001", "TimeSpan", [3,3.01]);

o = odeSimulator(net, ev1);

sol = o.simulate;

% plot(s(1).t, [s(1).X{1}.omega, s(2).X{1}.omega, s(3).X{1}.omega, s(6).X{1}.omega, s(8).X{1}.omega])