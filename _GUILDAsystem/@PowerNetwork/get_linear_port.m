function sct_port = get_linear_port(obj)
% Get the inputs and outputs of the linear model of the network (port of get_sys).
%
% The inputs are the inputs u of the components; the outputs are the outputs y of the
% components and yc of the controllers. The bus voltages are algebraic variables with the
% current balance 0 = Y v - (currents of the components) of each bus, Y the admittance
% matrix of the model. See PowerSystemModel.get_linear_port for the fields.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_port struct   % Fields sv_input, sv_output, sv_algebraic, cm_Y, tab_bus.
    end
    tab   = obj.get_variable_map();
    sv_V  = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    sv_tag = reshape(string(tools.vcellfun(@(b) string(b.s_tag), obj.a_Bus)), [], 1);
    sv_I  = reshape(string(tools.vcellfun(@(b) reshape(string(b.attach_tag(["Ire";"Iim"])), [], 1), obj.a_Bus)), [], 1);
    tab_bus = table(sv_tag, sv_V(1:2:end), sv_V(2:2:end), sv_I(1:2:end), sv_I(2:2:end), ...
                    VariableNames=["Bus","Vre","Vim","Ire","Iim"]);
    sct_port = struct("sv_input", tab.Label(tab.Kind == "u"), ...
                      "sv_output", [tab.Label(tab.Kind == "y"); tab.Label(tab.Kind == "yc")], ...
                      "sv_algebraic", sv_V, "cm_Y", obj.get_admittance_matrix.Variables, "tab_bus", tab_bus);
end
