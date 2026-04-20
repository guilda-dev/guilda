ev1 = eventset("FltBus", "B001", "Time", [3,3.01]);

o = odeSimulator(net, [0,30], ev1);

[t, s] = o.simulate;

plot(s(1).t, [s(1).X{1}.omega, s(2).X{1}.omega, s(3).X{1}.omega, s(6).X{1}.omega, s(8).X{1}.omega])