function set_input(obj, rv_u)
% Set the inputs of the component at the equilibrium (rv_Uequilibrium).
%
% The inputs, in the order of sv_u, are held for net.initialize(Method="FixedInput"),
% which solves the states, the bus voltages and the currents with these inputs (only the
% Pmech of the first generator of the slack bus is solved too). The edit is logged
% (LayerPackage.log_edit, tag "input"): it makes the equilibrium of the component stale
% and is listed in net.sct_stale.input, so the analyses (simulate, linearize, get_sys,
% the continuation power flow) and net.initialize() stop until
% net.initialize(Method="FixedInput") is run. net.initialize(Method="powerflow") or
% Method="OPF" replaces the edited inputs with the values of their solution.
% A value equal to the held one changes nothing. The component must be on a bus.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% gen = net.a_Bus{2}.a_Component{1};
% u = gen.rv_Uequilibrium;
% u(1) = u(1) + 0.1;                         % Pmech
% gen.set_input(u);
% net.initialize(Method="FixedInput");       % the slack generator balances the power
% ```
%
% See also PowerNetwork.initialize, Component.rv_Uequilibrium
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        rv_u (:,1) double {mustBeReal, mustBeFinite}   % Inputs in the order of sv_u.
    end
    arguments (Output)
    end
    if numel(rv_u) ~= numel(obj.sv_u)
        error(msg("GUILDA:Component:InputSize", char(obj.s_tag), char(string(numel(rv_u))), ...
                  char(string(numel(obj.sv_u))), char(join(string(obj.sv_u), ", "))))
    end
    if isempty(obj.a_Bus)
        error(msg("GUILDA:Component:InputNotConnected", char(obj.s_tag)))
    end
    rv_old = obj.rv_Uequilibrium;
    if isequal(rv_old, rv_u)
        return
    end
    obj.rv_Uequilibrium = rv_u;
    obj.log_edit("edit rv_Uequilibrium: " + tools.value_text(rv_old) + " -> " + tools.value_text(rv_u), "input");
end
