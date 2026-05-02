net = network.IEEE14bus;


avr = controller.AVR_DC1("avr");
pss = controller.PSS1("pss");

net.a_Bus{1}.a_Component{1}.add_local_controller(avr,pss)

net.initialize;