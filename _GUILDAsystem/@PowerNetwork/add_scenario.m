function sc = add_scenario(obj, s_tag, opt)
% Create a simulation scenario of the network and return it.
%
% The new scenario is a child of the network (net.a_Scenario, sc.a_PowerNetwork). Its tag
% shares the name space of the buses, branches and global controllers: a tag in use gets a
% number suffix (case1 -> case1002, as for the other layers) and the new tag is shown as
% INFO; read it from sc.s_tag. Add the disturbances with the methods of the scenario.
%
% From=sc0 copies the disturbances, Time, Options and Description of the scenario sc0 (of
% this or another network); sc0 does not change. The disturbances are checked against this
% network: when a check fails, no scenario is created. To move a scenario, copy it and
% remove the original: `net2.add_scenario(tag, From=sc); net1.remove_scenario(tag)`.
%
% Scenarios are not model data: the equilibrium does not become stale and nothing is
% logged as an edit.
%
% <@Examples>
% ```matlab
% sc = net.add_scenario("case1", Time=[0, 20]);
% sc.add_fault("B008", [0.10, 0.17]);
% sc.add_open_branch("EL003", [0.17, 20]);
% result = net.simulate(sc);
% other.add_scenario("case1", From=sc);     % a copy in another network
% ```
%
% See also PowerNetwork.remove_scenario, PowerNetwork.simulate, Scenario
%
% <@Group> Model building
    arguments (Input)
        obj
        s_tag (1,1) string {mustBeNonzeroLengthText}   % Tag of the new scenario; a number is added when a child of the network has it.
        opt.Time (1,2) double {mustBeSimulationTime}   % [s] Simulation time [t0, tend]. Default: From.Time, else [0, 10].
        opt.Description (1,1) string                   % Free text. Default: From.Description, else "".
        opt.From Scenario {mustBeScalarOrEmpty}        % Scenario to copy the disturbances and settings from (of this or another network).
    end
    arguments (Output)
        sc Scenario   % The new scenario, a child of the network.
    end
    sc = Scenario(obj, s_tag);
    obj.a_Scenario = [obj.a_Scenario; {sc}];
    try
        if isfield(opt, "From") && ~isempty(opt.From)
            sc0 = opt.From;
            sc.Time        = sc0.Time;
            sc.Options     = sc0.Options;
            sc.Description = sc0.Description;
            tab = sc0.tab_disturbance;
            sv_var = string(tab.Properties.VariableNames(2:end));
            for r = 1:height(tab)
                c_nv = cell(1, 0);
                for s_var = sv_var
                    x = tab.(s_var)(r,:);
                    if iscell(x)
                        x = x{1};
                    end
                    if s_var == "InputMethod" && x == ""
                        continue
                    end
                    c_nv = [c_nv, {s_var, x}]; %#ok<AGROW>
                end
                sc.add_disturbance(tab.Tag(r), c_nv{:});
            end
        end
        for s_name = intersect(["Time", "Description"], string(fieldnames(opt)).')
            sc.(s_name) = opt.(s_name);
        end
    catch ME
        obj.remove_scenario(sc.s_tag);
        rethrow(ME)
    end
end
