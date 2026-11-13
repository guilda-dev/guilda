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
        [sys, flag, output] = get_sys(obj, opt)
    end
    methods (Access=protected)
        sct_port = get_linear_port(obj, s_port)
    end

    methods
        function tp = get.tab_parameter(obj)
            c_tab = cellfun(@(p) p.tab_parameter, obj.a_Parameter, 'UniformOutput', false);
            sv_tag = string(cellfun(@(p) p.s_tag, obj.a_Parameter, 'UniformOutput', false));
            tp = table(c_tab{:}, 'VariableNames', sv_tag);
        end
        function set.tab_parameter(obj, tp)
            % Each container stores its column and logs only the values that changed.
            sv_tag = string(cellfun(@(p) p.s_tag, obj.a_Parameter, 'UniformOutput', false)).';
            sv_col = string(tp.Properties.VariableNames);
            if ~isequal(sv_col, sv_tag)
                s_unknown = setdiff(sv_col, sv_tag, 'stable');
                if ~isempty(s_unknown)
                    error(msg("GUILDA:PowerSystemModel:UnknownParameterGroup", char(string(obj)), char(s_unknown(1)), char(strjoin(sv_tag, ", "))))
                end
            end
            for s_col = sv_col
                a_para = obj.a_Parameter{sv_tag == s_col};
                a_para.tab_parameter = tp.(s_col);
            end
        end
    end
end
