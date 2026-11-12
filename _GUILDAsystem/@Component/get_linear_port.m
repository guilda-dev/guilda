function sct_port = get_linear_port(obj, s_port)
% Get the inputs and outputs of the linear model of the component (port of get_sys).
%
% Port "V2I": the inputs are the bus voltage, the inputs u of the component and the
% inputs uc of its local controllers; the outputs are the current [Ire; Iim] of the
% component, its outputs y and the outputs yc of its controllers. Port "I2V": the
% current is an input and the bus voltage an output (an algebraic variable eliminated by
% get_ss). See PowerSystemModel.get_linear_port for the fields.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        s_port (1,1) string {mustBeMember(s_port, ["V2I","I2V"])}   % Input and output ports.
    end
    arguments (Output)
        sct_port struct   % Fields sv_input, sv_output, sv_algebraic, cm_Y, tab_bus.
    end
    tab  = obj.get_variable_map();
    sv_V = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    sv_I = reshape(string(obj.attach_tag(["Ire";"Iim"])), [], 1);
    sv_u = [tab.Label(tab.Kind == "u"); tab.Label(tab.Kind == "uc")];
    sv_y = [tab.Label(tab.Kind == "y"); tab.Label(tab.Kind == "yc")];
    tab_bus = table(string(obj.a_Bus.s_tag), sv_V(1), sv_V(2), sv_I(1), sv_I(2), ...
                    VariableNames=["Bus","Vre","Vim","Ire","Iim"]);
    if s_port == "V2I"
        sct_port = struct("sv_input", [sv_V; sv_u], "sv_output", [sv_I; sv_y], ...
                          "sv_algebraic", strings(0,1), "cm_Y", zeros(0), "tab_bus", tab_bus);
    else
        sct_port = struct("sv_input", [sv_I; sv_u], "sv_output", [sv_V; sv_y], ...
                          "sv_algebraic", sv_V, "cm_Y", 0, "tab_bus", tab_bus);
    end
end
