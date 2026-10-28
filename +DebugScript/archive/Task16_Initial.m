ev2 = odeEventSet("ev1", net,"TimeSpan",0, "OffsetUnit","SG1B001","OffsetState","delta","OffsetValue",0.001);

sol = net.simulate([0,150], ev2, "TimeLimit", 30);

xsol = sol.odeResults;

figure
hold on
arrayfun(@(i) plot(xsol.t, xsol.Bus(i).Component(1).X.omega), [1,2,3,6,8]);