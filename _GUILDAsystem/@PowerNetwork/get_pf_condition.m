function varargout = get_pf_condition(obj, opt)
% Return the power-flow condition of the network: the data the power flow runs with.
%
% Stacks Bus.get_pf_condition of every bus (in the order of a_Bus) and adds the bus
% admittance matrix. These are the data net.calculate_powerflow passes to net.solver_PF;
% net.calculate_fixed_input_powerflow takes its slack bus and admittance matrix from them.
%
% - Bus: Type ("slack", "PV" or "PQ"), Varg, V, P, Q (NaN where the type does not set the
%   value); row names = bus tags.
% - Y: the bus admittance matrix as a table, the same as get_admittance_matrix.
%
% When no bus is the slack bus (l_isSlack), the bus of tools.slack_bus_index is the slack
% bus of the table (INFO GUILDA:PowerNetwork:SlackSelected): the first bus that has a
% component with Q = NaN, otherwise the first bus that has a component. Its row is the one
% Bus.get_pf_condition gives for a slack bus (its set V and Varg); a selected bus without
% a component with Q = NaN warns (GUILDA:PowerNetwork:SlackWithoutQnan). The network is not
% changed: l_isSlack is never written. A network without buses stops with
% GUILDA:PowerNetwork:NoBus, and a network whose buses have no components with
% GUILDA:PowerNetwork:NoSlackCandidate.
%
% With Display=true (default) the Bus table is printed (Y is not); with no output
% nothing is returned.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.get_pf_condition();                          % print the bus table
% sct = net.get_pf_condition(Display=false);
% sct.Bus(sct.Bus.Type == "PV", :)                 % the PV buses
% cm_Y = sct.Y{:,:};                               % admittance matrix (a_Bus order)
% ```
%
% See also Bus.get_pf_condition, PowerNetwork.calculate_powerflow, PowerNetwork.get_admittance_matrix
%
% <@Group> Power flow
    arguments (Input)
        obj
        opt.Display (1,1) logical = true   % Print the bus table.
    end
    arguments (Output, Repeating)
        varargout   % sct_PFcondition: struct with the tables Bus and Y.
    end
    if isempty(obj.a_Bus)
        error(msg("GUILDA:PowerNetwork:NoBus", string(obj)))
    end
    i_slack = tools.slack_bus_index(obj);
    if isempty(i_slack)
        error(msg("GUILDA:PowerNetwork:NoSlackCandidate", string(obj)))
    end
    tab_bus = tools.vcellfun(@(b) b.get_pf_condition, obj.a_Bus);
    tab_bus.Properties.RowNames = reshape(string(obj.a_Bus), [], 1);
    if tab_bus.Type(i_slack) ~= "slack"   % selected: the row of a slack bus, l_isSlack not written
        bus = obj.a_Bus{i_slack};
        show_msg("info", "GUILDA:PowerNetwork:SlackSelected", string(bus))
        if ~any(cellfun(@(c) isnan(c.tab_parameter.powerflow.Q), bus.a_Component))   % as when l_isSlack is set
            show_msg("warning", "GUILDA:PowerNetwork:SlackWithoutQnan", string(bus), string(bus.a_Component{1}))
        end
        tp = bus.tab_parameter.powerflow;
        tab_bus(i_slack,:) = [table("slack", 'VariableNames', "Type"), ...
                              array2table([tp.Varg, tp.V, NaN, NaN], "VariableNames", ["Varg","V","P","Q"])];
    end
    sct_PFcondition = struct("Bus", tab_bus, "Y", obj.get_admittance_matrix);

    if opt.Display
        fprintf("%s\n%s\n", "Bus", formattedDisplayText(tab_bus));
    end
    if ~opt.Display || nargout > 0
        varargout = {sct_PFcondition};
    end
end
