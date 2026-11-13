function sct_port = get_linear_port(obj)
% Get the inputs and outputs of the linear model of the local controller (port of get_sys).
%
% The inputs are the voltage of the bus of its component and its inputs (rows Vre, Vim
% and uc of its variable map); the outputs are its outputs (rows "yc"). See
% PowerSystemModel.get_linear_port for the fields.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_port struct   % Fields sv_input, sv_output, sv_algebraic, cm_Y, tab_bus.
    end
    comp = obj.observed_component();
    tab  = obj.get_variable_map();
    sv_V = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    sv_I = reshape(string(comp.a_Bus.attach_tag(["Ire";"Iim"])), [], 1);
    tab_bus = table(string(comp.a_Bus.s_tag), sv_V(1), sv_V(2), sv_I(1), sv_I(2), ...
                    VariableNames=["Bus","Vre","Vim","Ire","Iim"]);
    sct_port = struct("sv_input", [sv_V; tab.Label(tab.Kind == "uc")], ...
                      "sv_output", tab.Label(tab.Kind == "yc"), ...
                      "sv_algebraic", strings(0,1), "cm_Y", zeros(0), "tab_bus", tab_bus);
end
