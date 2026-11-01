function i_bus = slack_bus_index(net)
% Return the index in net.a_Bus of the slack bus, or of the bus that would be selected.
%
% This is the bus that is set with l_isSlack. When none is set, it is the first bus that
% has a component with Q = NaN, otherwise the first bus that has a component. It is empty
% when no bus has a component.
%
% Inputs:
% - `net`: Network to look at. It is only read.
%
% <@Examples>
% ```matlab
% i_bus = tools.slack_bus_index(network.IEEE14bus);
% ```
%
% See also PowerNetwork.calculate_powerflow, PowerNetwork.build_opf_problem, tools.network_to_mpc
    arguments (Output)
        i_bus % Index in net.a_Bus; empty when no bus has a component.
    end
    a_Bus = net.a_Bus;
    i_bus = find(cellfun(@(b) b.l_isSlack, a_Bus), 1);
    if isempty(i_bus)
        i_bus = find(cellfun(@(b) any(cellfun(@(c) isnan(c.para_powerflow.Q), b.a_Component)), a_Bus), 1);
    end
    if isempty(i_bus)
        i_bus = find(cellfun(@(b) ~isempty(b.a_Component), a_Bus), 1);
    end
end
