function add_avr(net, s_dirpath)
% controller/avr/parameter.csv : AVR_DC1 parameters of the generator at each Bus
    arguments (Input)
        net         (1,1) PowerNetwork  % Network being built.
        s_dirpath                       % Folder that holds the controller/ CSV files.
    end
    tab_avr = readtable(fullfile(s_dirpath, "controller", "avr", "parameter.csv"));
    for i = 1:height(tab_avr)
        i_bus = tab_avr.Bus(i);
        c_avr = namedargs2cell(table2struct(removevars(tab_avr(i,:), "Bus")));
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(controller.avr.AVR_DC1("avr" + i_bus, c_avr{:}));
    end
end
