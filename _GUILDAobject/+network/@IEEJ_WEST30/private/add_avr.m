function add_avr(net, s_section)
% controller/avr/parameter.csv : AVR_DC1 parameters of the generator at each Bus
    arguments (Input)
        net         (1,1) PowerNetwork  % Network being built.
        s_section                       % Folder that holds the controller/ CSV files.
    end
    tab_avr = readtable(fullfile(s_section, "controller", "avr", "parameter.csv"));
    for i = 1:height(tab_avr)
        i_bus = tab_avr.Bus(i);
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller("avr-DC1", parameter=removevars(tab_avr(i,:), "Bus"));
    end
end
