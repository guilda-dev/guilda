function add_governor(net, s_section)
% controller/governor/parameter.csv : IEEJ_LPTn governor (n = LPT) of the generator at each Bus
    arguments (Input)
        net         (1,1) PowerNetwork  % Network being built.
        s_section                       % Folder that holds the controller/ CSV files.
    end
    tab_gov = readtable(fullfile(s_section, "controller", "governor", "parameter.csv"));
    for i = 1:height(tab_gov)
        i_bus = tab_gov.Bus(i);
        c_gov = namedargs2cell(table2struct(removevars(tab_gov(i,:), ["Bus","LPT"])));
        gov   = feval("controller.governor.IEEJ_LPT" + tab_gov.LPT(i), "gov" + i_bus, c_gov{:});
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(gov);
    end
end
