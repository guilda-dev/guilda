net = network.IEEE14bus;

% avr1 = controller.avr.AVR_DC1("avr");
avr1 = controller.avr.AVR_ST1("avr1");
pss1 = controller.pss.PSS1("pss1");

% avr2 = controller.avr.AVR_DC1("avr");
avr2 = controller.avr.AVR_ST1("avr2");
pss2 = controller.pss.PSS1("pss2");

net.a_Bus{1}.a_Component{1}.add_local_controller(avr1, pss1)
net.a_Bus{2}.a_Component{1}.add_local_controller(avr2, pss2)

% net.a_Bus{1}.a_Component{1}.add_local_controller(avr1)
% net.a_Bus{2}.a_Component{1}.add_local_controller(avr2)

net.initialize;
    