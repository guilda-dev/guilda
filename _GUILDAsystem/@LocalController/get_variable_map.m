function tab = get_variable_map(obj)
% Return the variable map of the local controller.
%
% Variable map of the controller: its rows of the map of its component
% (comp.get_variable_map(), with the same columns and labels), and the voltage of the bus:
%   1. x: states of the controller
%   2. Vre, Vim of the bus of its component
%   3. uc: inputs of the controller
%   4. yc: outputs of the controller (signals)
% The rows x, Vre, Vim and uc come first: they are the order of the point vector of
% con.get_sys(point). Index counts from 1 here. The column Equilibrium holds the value of
% each row at the equilibrium set by net.initialize (the stored rv_Xequilibrium,
% c_Vequilibrium and rv_Uequilibrium, and the outputs evaluated there); it is NaN when
% the equilibrium has not been computed yet. Where each input is read is in the
% connection map of the component (comp.get_variable_map), whose sources are not rows of
% this map.
%
% <@Examples>
% ```matlab
% avr = net.a_Bus{1}.a_Component{1}.a_LocalController{1};
% tab = avr.get_variable_map();
% res = avr.get_sys(tab.Equilibrium(tab.Role == "variable"));   % same as avr.get_sys()
% ```
%
% See also Component.get_variable_map, PowerSystemModel.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table   % One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus, Equilibrium.
    end
    comp  = obj.observed_component();
    bus   = comp.a_Bus;
    s_bus = string(bus.s_tag);
    s_own = string(obj.s_tag);
    sv_x  = reshape(string(obj.sv_x), [], 1);
    sv_u  = reshape(string(obj.sv_u), [], 1);
    sv_y  = reshape(string(obj.sv_y), [], 1);
    sv_yl = sv_y;
    lv    = ismember(sv_yl, sv_x);
    sv_yl(lv) = "Y_" + sv_yl(lv);           % an output with the name of a state is "Y_" + name
    n_x = numel(sv_x);  n_u = numel(sv_u);  n_y = numel(sv_y);
    sv_kind  = [repmat("x", n_x, 1); "Vre"; "Vim"; repmat("uc", n_u, 1); repmat("yc", n_y, 1)];
    sv_role  = [repmat("variable", n_x + 2 + n_u, 1); repmat("signal", n_y, 1)];
    sv_owner = [repmat(s_own, n_x, 1); s_bus; s_bus; repmat(s_own, n_u + n_y, 1)];
    sv_name  = [sv_x; "Vre"; "Vim"; sv_u; sv_y];
    sv_label = [tag(obj, sv_x); tag(bus, ["Vre";"Vim"]); tag(obj, sv_u); tag(obj, sv_yl)];

    % The equilibrium: NaN until net.initialize has computed it (or when its size is wrong)
    n = numel(sv_kind);
    rv_eq = nan(n,1);
    net = bus.a_PowerNetwork;
    if ~isempty(net) && ~any(net.sct_stale.powerflow == net.s_notInitialized) ...
            && ~any(obj.sct_stale.equilibrium == obj.s_notInitialized) ...
            && numel(obj.rv_Xequilibrium) == n_x && numel(obj.rv_Uequilibrium) == n_u
        x = reshape(obj.rv_Xequilibrium, [], 1);
        V = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)];
        u = reshape(obj.rv_Uequilibrium, [], 1);
        y = zeros(0,1);
        if n_y > 0
            y = reshape(obj.f_Y(0, x, V, u), [], 1);
        end
        rv_eq = [x; V; u; y];
    end
    tab = table((1:n)', sv_kind, sv_role, sv_owner, sv_name, sv_label, repmat(s_bus, n, 1), rv_eq, ...
                VariableNames=["Index","Kind","Role","Owner","Name","Label","Bus","Equilibrium"]);
end


function sv = tag(owner, sv_name)
    % Tagged name, as in the Label column of the map of the component
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(owner.attach_tag(reshape(string(sv_name), [], 1))), [], 1);
    end
end
