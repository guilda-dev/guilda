ev1 = odeEventSet("ev1", net, "TimeSpan", [3,3.01], "TripUnit", "SG1B002");

o = odeSimulator(net, ev1);

[t, s] = o.simulate;

plot(s(1).t, [s(1).X{1}.omega, s(2).X{1}.omega, s(3).X{1}.omega, s(6).X{1}.omega, s(8).X{1}.omega])
