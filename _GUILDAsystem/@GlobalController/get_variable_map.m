function tab = get_variable_map(obj)
% Return the variable map of the global controller.
%
% Variable map of the controller: its rows of the map of the network
% (net.get_variable_map(), with the same columns and labels), and the voltages of all buses:
%   1. x: states of the controller
%   2. Vre, Vim of each bus in a_Bus (B1 Vre, B1 Vim, B2 Vre, ...)
%   3. uc: inputs of the controller, unit by unit (sv_u of unit 1, sv_u of unit 2, ...),
%      labelled gc.attach_tag(name + "_" + unit tag)
%   4. yc: outputs of the controller, unit by unit (signals), labelled the same way
% The rows x, Vre, Vim and uc come first: they are the order of the point vector of
% gc.get_sys(point). Index counts from 1 here. The column Equilibrium holds the value of
% each row at the equilibrium set by net.initialize (the stored rv_Xequilibrium,
% c_Vequilibrium of the buses and rv_Uequilibrium, and the outputs evaluated there); it
% is NaN when the equilibrium has not been computed yet. Which outputs and states each
% input observes, and where each output goes, is in the connection map of the network
% (net.get_variable_map), whose sources and targets are not rows of this map.
%
% <@Examples>
% ```matlab
% gc  = net.a_GlobalController{1};
% tab = gc.get_variable_map();
% tab(tab.Kind == "uc", ["Name","Label","Equilibrium"])
% ```
%
% See also PowerNetwork.get_variable_map, PowerSystemModel.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table   % One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus, Equilibrium.
    end
    net    = obj.a_PowerNetwork;
    a_bus  = net.a_Bus;
    a_unit = obj.controlledUnits;
    s_own  = string(obj.s_tag);
    sv_x   = reshape(string(obj.sv_x), [], 1);
    sv_u   = reshape(string(obj.sv_u), [], 1);
    sv_y   = reshape(string(obj.sv_y), [], 1);
    sv_unit = reshape(string(tools.vcellfun(@(c) string(c.s_tag), a_unit)), 1, []);
    sv_bus  = reshape(string(tools.vcellfun(@(b) string(b.s_tag), a_bus)), 1, []);
    % names and labels of the inputs and outputs: one set per unit
    sv_uc = reshape(repmat(sv_u, 1, numel(sv_unit)), [], 1);
    sv_yc = reshape(repmat(sv_y, 1, numel(sv_unit)), [], 1);
    sv_ucl = reshape(sv_u + "_" + sv_unit, [], 1);
    sv_ycl = reshape(sv_y + "_" + sv_unit, [], 1);
    n_x = numel(sv_x);  n_v = 2*numel(sv_bus);  n_u = numel(sv_uc);  n_y = numel(sv_yc);
    sv_kind  = [repmat("x", n_x, 1); repmat(["Vre";"Vim"], n_v/2, 1); repmat("uc", n_u, 1); repmat("yc", n_y, 1)];
    sv_role  = [repmat("variable", n_x + n_v + n_u, 1); repmat("signal", n_y, 1)];
    sv_vbus  = reshape(repmat(sv_bus, 2, 1), [], 1);
    sv_owner = [repmat(s_own, n_x, 1); sv_vbus; repmat(s_own, n_u + n_y, 1)];
    sv_name  = [sv_x; repmat(["Vre";"Vim"], n_v/2, 1); sv_uc; sv_yc];
    sv_V     = tools.vcellfun(@(b) tag(b, ["Vre";"Vim"]), a_bus);
    sv_label = [tag(obj, sv_x); reshape(string(sv_V), [], 1); tag(obj, sv_ucl); tag(obj, sv_ycl)];
    sv_where = [strings(n_x, 1); sv_vbus; strings(n_u + n_y, 1)];

    % The equilibrium: NaN until net.initialize has computed it (or when its size is wrong)
    n = numel(sv_kind);
    rv_eq = nan(n,1);
    if ~any(net.sct_stale.powerflow == net.s_notInitialized) ...
            && ~any(obj.sct_stale.equilibrium == obj.s_notInitialized) ...
            && numel(obj.rv_Xequilibrium) == n_x && numel(obj.rv_Uequilibrium) == n_u
        x = reshape(obj.rv_Xequilibrium, [], 1);
        V = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], a_bus);
        V = [zeros(0,1); V];
        u = reshape(obj.rv_Uequilibrium, [], 1);
        y = zeros(0,1);
        if n_y > 0
            y = reshape(obj.f_Y(0, x, V, u), [], 1);
        end
        rv_eq = [x; V; u; y];
    end
    tab = table((1:n)', sv_kind, sv_role, sv_owner, sv_name, sv_label, sv_where, rv_eq, ...
                VariableNames=["Index","Kind","Role","Owner","Name","Label","Bus","Equilibrium"]);
end


function sv = tag(owner, sv_name)
    % Tagged name, as in the Label column of the map of the network
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(owner.attach_tag(reshape(string(sv_name), [], 1))), [], 1);
    end
end
