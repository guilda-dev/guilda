function varargout = get_opf_condition(obj, opt)
% Return the optimal-power-flow condition of the network: the data the OPF runs with.
%
% Stacks Bus.get_opf_condition of every bus (in the order of a_Bus, the components bus by
% bus) and Branch.get_opf_condition of every branch (in the order of a_Branch). These are
% the tables net.calculate_optimal_powerflow and net.build_opf_problem pass to
% net.solver_OPF; row names are the tags.
%
% - Bus: Vmin, Vmax, Gshunt, Bshunt, Type, V, Varg.
% - Component: Bus, HP, fP, HQ, fQ, P0, Q0, Pmin, Pmax, Qmin, Qmax (a load with infinite
%   bounds is fixed to its powerflow P, Q).
% - Branch: From, To, Y (2x2 admittance matrix per row), X, tap, phase, Pmax, Qmax,
%   Vargmax, Imax, Smax.
%
% With Display=true (default) the three tables are printed under the headings "Bus",
% "Component" and "Branch", the Branch table without the column Y (the returned table
% keeps it); with no output nothing is returned.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.get_opf_condition();                               % print the three tables
% sct = net.get_opf_condition(Display=false);
% sct.Component("B002SG1", ["Pmin","Pmax"])              % bounds of one generator
% ```
%
% See also Bus.get_opf_condition, Branch.get_opf_condition, PowerNetwork.calculate_optimal_powerflow
%
% <@Group> OPF
    arguments (Input)
        obj
        opt.Display (1,1) logical = true   % Print the tables.
    end
    arguments (Output, Repeating)
        varargout   % sct_OPFcondition: struct with the tables Bus, Component and Branch.
    end
    a_bus = reshape(obj.a_Bus, [], 1);
    a_br  = reshape(obj.a_Branch, [], 1);
    c_bus = cell(numel(a_bus), 1);
    c_com = cell(numel(a_bus), 1);
    for i = 1:numel(a_bus)
        [c_bus{i}, c_com{i}] = a_bus{i}.get_opf_condition(Display=false);
    end
    c_br = cellfun(@(br) br.get_opf_condition(Display=false), a_br, "UniformOutput", false);

    [tab_bus0, tab_com0, tab_br0] = empty_tables();
    sct_OPFcondition = struct( ...
              "Bus", vertcat(tab_bus0, c_bus{:}), ...
        "Component", vertcat(tab_com0, c_com{:}), ...
           "Branch", vertcat(tab_br0, c_br{:}));

    if opt.Display
        for s_name = ["Bus","Component","Branch"]
            tab = sct_OPFcondition.(s_name);
            if s_name == "Branch"
                tab = removevars(tab, "Y");
            end
            fprintf("%s\n%s\n", s_name, formattedDisplayText(tab));
        end
    end
    if ~opt.Display || nargout > 0
        varargout = {sct_OPFcondition};
    end
end


function [tab_bus, tab_com, tab_br] = empty_tables()
% Tables without rows, with the columns of Bus.get_opf_condition and
% Branch.get_opf_condition (the result of a network without buses or branches)
    tab_bus = [array2table(zeros(0,4), "VariableNames", ["Vmin","Vmax","Gshunt","Bshunt"]), ...
               table(strings(0,1), 'VariableNames', "Type"), ...
               array2table(zeros(0,2), "VariableNames", ["V","Varg"])];
    tab_com = [table(strings(0,1), 'VariableNames', "Bus"), ...
               array2table(zeros(0,10), "VariableNames", ["HP","fP","HQ","fQ","P0","Q0","Pmin","Pmax","Qmin","Qmax"])];
    tab_br  = [table(strings(0,1), strings(0,1), complex(zeros(0,2,2)), 'VariableNames', ["From","To","Y"]), ...
               array2table(zeros(0,8), "VariableNames", ["X","tap","phase","Pmax","Qmax","Vargmax","Imax","Smax"])];
end
