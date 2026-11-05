function add_avr_pss(net, s_dirpath)
% controller/avr/parameter.csv : AVR_ST1 parameters of the generator at each Bus
% controller/pss/parameter.csv : PSS1 parameters of the generator at each Bus
    arguments (Input)
        net         (1,1) PowerNetwork  % Network being built.
        s_dirpath                       % Folder that holds the controller/ CSV files.
    end
    tab_avr = readtable(fullfile(s_dirpath, "controller", "avr", "parameter.csv"));
    tab_pss = readtable(fullfile(s_dirpath, "controller", "pss", "parameter.csv"));
    for i = 1:height(tab_avr)
        i_bus = tab_avr.Bus(i);
        c_avr = namedargs2cell(table2struct(removevars(tab_avr(i,:), "Bus")));
        avr   = controller.avr.AVR_ST1("avr" + i_bus, c_avr{:});
        i_pss = find(tab_pss.Bus == i_bus);
        gen   = net.a_Bus{i_bus}.a_Component{1};
        if isempty(i_pss)
            gen.add_local_controller(avr);
        else
            c_pss = namedargs2cell(table2struct(removevars(tab_pss(i_pss,:), "Bus")));
            gen.add_local_controller(avr, controller.pss.PSS1("pss" + i_bus, c_pss{:}));
        end
    end
end
