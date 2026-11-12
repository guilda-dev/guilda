function Point = v3_get_sys_point(layer, x, V, u)
% Convert the positional point x, V, u of get_sys to the Point option.
%
% v3 compatibility hook of PowerSystemModel.get_sys: comp.get_sys(x, V, u),
% con.get_sys(x, V, u) and gc.get_sys(x, V, u) warn once
% (GUILDA:Deprecated:GetSysPositionalPoint) and return the same point as a Point vector:
%
% - Component: [x; states of its local controllers at their equilibrium; V; u], the order
%   of the rows x, Vre, Vim, u of comp.get_variable_map().
% - LocalController: [x; V; u] (its states, the voltage of the bus of its component, its
%   inputs).
% - GlobalController: [x; V; u] (its states, the voltages of all buses, its inputs).
%
% An empty argument is the equilibrium value. A Bus or PowerNetwork has no positional point
% and stops with GUILDA:v3_get_sys_point:Positional.
%
% See also PowerSystemModel.get_sys, Deprecated
    arguments (Input)
        layer          % Layer of the call.
        x (:,1) double % States (empty: the equilibrium).
        V (:,1) double % [pu] Voltage (empty: the equilibrium).
        u (:,1) double % Inputs (empty: the equilibrium).
    end
    arguments (Output)
        Point (:,1) double % Point vector in the order of the variables of the layer.
    end
    if ~(isa(layer, "Component") || isa(layer, "LocalController") || isa(layer, "GlobalController"))
        error(msg("GUILDA:v3_get_sys_point:Positional", class(layer)))
    end
    Deprecated("GetSysPositionalPoint", class(layer));
    if isempty(x), x = reshape(layer.rv_Xequilibrium, [], 1); end
    if isempty(u), u = reshape(layer.rv_Uequilibrium, [], 1); end
    if isempty(V)
        if isa(layer, "GlobalController")
            V = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], layer.a_PowerNetwork.a_Bus);
        else
            V = [real(layer.c_Vequilibrium); imag(layer.c_Vequilibrium)];
        end
    end
    if isa(layer, "Component")
        x = [x; reshape(layer.rv_Xequilibrium_all(numel(layer.sv_x)+1:end), [], 1)];
    end
    Point = [x; V; u];
end
