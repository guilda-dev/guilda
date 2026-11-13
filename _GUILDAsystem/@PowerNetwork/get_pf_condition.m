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
% The slack bus is the bus with l_isSlack = true; GUILDA never selects one. A network
% without buses stops with GUILDA:PowerNetwork:NoBus, and a network without a slack bus
% with GUILDA:PowerNetwork:NoSlackBus, which tells how to set one. The network is not
% changed.
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
    tab_bus = tools.vcellfun(@(b) b.get_pf_condition, obj.a_Bus);
    tab_bus.Properties.RowNames = reshape(string(obj.a_Bus), [], 1);
    if ~any(tab_bus.Type == "slack")
        error(msg("GUILDA:PowerNetwork:NoSlackBus", string(obj)))
    end
    sct_PFcondition = struct("Bus", tab_bus, "Y", obj.get_admittance_matrix);

    if opt.Display
        fprintf("%s\n%s\n", "Bus", formattedDisplayText(tab_bus));
    end
    if ~opt.Display || nargout > 0
        varargout = {sct_PFcondition};
    end
end
