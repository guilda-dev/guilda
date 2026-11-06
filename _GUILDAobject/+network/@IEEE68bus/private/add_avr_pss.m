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
        gen   = net.a_Bus{i_bus}.a_Component{1};
        gen.add_local_controller("avr-ST1", parameter=removevars(tab_avr(i,:), "Bus"));
        i_pss = find(tab_pss.Bus == i_bus);
        if ~isempty(i_pss)
            gen.add_local_controller("pss-PSS1", parameter=removevars(tab_pss(i_pss,:), "Bus"));
        end
    end
end
