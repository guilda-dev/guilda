function add_governor(net, s_dirpath)
% controller/governor/parameter.csv : governor of the generator at each Bus
%   LPT selects controller.governor.IEEJ_LPT<LPT>; the other columns are its parameters.
    arguments (Input)
        net         (1,1) PowerNetwork  % Network being built.
        s_dirpath                       % Folder that holds the controller/ CSV files.
    end
    tab_gov = readtable(fullfile(s_dirpath, "controller", "governor", "parameter.csv"));
    for i = 1:height(tab_gov)
        i_bus = tab_gov.Bus(i);
        c_gov = namedargs2cell(table2struct(removevars(tab_gov(i,:), ["Bus","LPT"])));
        f_gov = str2func("controller.governor.IEEJ_LPT" + tab_gov.LPT(i));
        net.a_Bus{i_bus}.a_Component{1}.add_local_controller(f_gov("gov" + i_bus, c_gov{:}));
    end
end
