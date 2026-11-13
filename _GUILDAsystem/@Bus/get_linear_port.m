function sct_port = get_linear_port(obj)
% Get the inputs and outputs of the linear model of the bus (port of get_sys).
%
% The inputs are the bus voltage, the inputs u of the components and the inputs uc of
% their local controllers; the outputs are the current [Ire; Iim] of the bus (the sum of
% the currents of its components), the outputs y and the outputs yc. See
% PowerSystemModel.get_linear_port for the fields.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_port struct   % Fields sv_input, sv_output, sv_algebraic, cm_Y, tab_bus.
    end
    tab  = obj.get_variable_map();
    sv_V = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    sv_I = reshape(string(obj.attach_tag(["Ire";"Iim"])), [], 1);
    sv_u = [tab.Label(tab.Kind == "u"); tab.Label(tab.Kind == "uc")];
    sv_y = [tab.Label(tab.Kind == "y"); tab.Label(tab.Kind == "yc")];
    tab_bus = table(string(obj.s_tag), sv_V(1), sv_V(2), sv_I(1), sv_I(2), ...
                    VariableNames=["Bus","Vre","Vim","Ire","Iim"]);
    sct_port = struct("sv_input", [sv_V; sv_u], "sv_output", [sv_I; sv_y], ...
                      "sv_algebraic", strings(0,1), "cm_Y", zeros(0), "tab_bus", tab_bus);
end
