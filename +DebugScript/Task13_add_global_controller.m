net = network.IEEE14bus;

c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};

Gcon = controller.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);

net.add_global_controller(Gcon);

net.initialize;
