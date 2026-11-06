classdef PowerSystemModel < LayerPackage
% Base class of the classes that constitute the power system model.
%
% PowerNetwork, Bus, Branch, Component, LocalController and GlobalController derive from
% it. It separates the classes that make up the power system model from those intended
% for analysis assistance:
%
% - Classes that constitute the power system model inherit from PowerSystemModel.
% - Classes intended for analysis assistance inherit from auxiliary.
%
% What is out of date is kept by each layer (LayerPackage: `sct_stale`); only
% PowerNetwork.initialize brings it up to date. get_Hz gives every model the nominal
% frequency of its network.
%
% See also auxiliary, LayerPackage, Parameter

    properties(Dependent) % Parameter
        tab_parameter                       % Parameter table: the a_Parameter tables side by side; writing it writes the changed parameters. <@Type> table
    end
    properties(SetAccess=protected, Hidden) % Parameter
        a_Parameter (:,1) cell = cell(0,1)  % Parameter containers, one per column of tab_parameter (column name: the s_tag of the container). <@Type> Parameter cell array (Nx1)
    end

    methods
        Hz = get_Hz(obj)
    end

    methods
        function tp = get.tab_parameter(obj)
            c_tab = cellfun(@(p) p.tab_parameter, obj.a_Parameter, 'UniformOutput', false);
            sv_tag = string(cellfun(@(p) p.s_tag, obj.a_Parameter, 'UniformOutput', false));
            tp = table(c_tab{:}, 'VariableNames', sv_tag);
        end
        function set.tab_parameter(obj, tp)
            % Only the changed values are written, so only they are logged. A value of
            % another class is written even when equal, so that its class is checked.
            sv_tag = string(cellfun(@(p) p.s_tag, obj.a_Parameter, 'UniformOutput', false));
            sv_col = string(tp.Properties.VariableNames);
            s_unknown = setdiff(sv_col, sv_tag, 'stable');
            if ~isempty(s_unknown)
                error(msg("GUILDA:PowerSystemModel:UnknownParameterGroup", char(string(obj)), char(s_unknown(1)), char(strjoin(sv_tag, ", "))))
            end
            for s_col = sv_col
                a_para  = obj.a_Parameter{sv_tag == s_col};
                tab_new = tp.(s_col);
                for s_name = string(tab_new.Properties.VariableNames)
                    val_old = a_para.(s_name);
                    val_new = tab_new.(s_name);
                    if ~(isequaln(val_old, val_new) && strcmp(class(val_old), class(val_new)))
                        a_para.(s_name) = val_new;
                    end
                end
            end
        end
    end
end
