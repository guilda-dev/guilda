function rv = get_point(obj, Step, tab_map)
% Get the values of the variable map at a step of the continuation power flow path.
%
% Returns the operating point at step Step (the index in rv_lambda, as r_noseStep), in
% the order of the rows of tab_map (by default the whole tab_variable, so rv is a point
% for net.get_sys(rv)). tab_map may be any part of tab_variable, e.g. the rows x, Vre,
% Vim, u, uc of the variable map of a bus or component of the analysed network
% (bus.get_variable_map(), comp.get_variable_map()); its rows are found by Kind, Owner,
% Name and Bus. The other rows of a variable map (the signals y, yc) are not in the result
% and stop with GUILDA:ResultCPF:UnknownVariable. Step must be an integer from 1 to
% numel(rv_lambda) (GUILDA:ResultCPF:PointStep); there is no interpolation between steps.
% How the point of a step is made is in the class help (ResultCPF). net.get_sys({result,
% rv_step}) reads the steps rv_step through this method, one section per step.
%
% <@Examples>
% ```matlab
% result = net.calculate_continuation_powerflow(LoadBus="B014");
% x0 = result.get_point(1);                     % the equilibrium of net.initialize
% xn = result.get_point(result.r_noseStep);     % the nose
% V  = result.get_point(5, net.a_Bus{14}.get_variable_map());   % rows of one bus
% lin = net.get_sys({result, [1 result.r_noseStep]});          % two sections
% ```
%
% See also ResultCPF, PowerNetwork.get_variable_map, SolverLIN
    arguments (Input)
        obj
        Step     (1,1) double {mustBeReal}  % Step: an integer from 1 to numel(rv_lambda).
        tab_map  table = obj.tab_variable   % Rows to return (a variable map or a part of it).
    end
    arguments (Output)
        rv  % Values in the order of the rows of tab_map (column).
    end
    n_step = size(obj.rm_variable, 1);
    if ~(Step >= 1 && Step <= n_step && Step == round(Step))
        error(msg("GUILDA:ResultCPF:PointStep", sprintf("%g", Step), sprintf("%d", n_step)))
    end
    if height(tab_map) == 0
        rv = zeros(0,1);
        return
    end
    if ~all(ismember(["Kind","Owner","Name","Bus"], string(tab_map.Properties.VariableNames)))
        error(msg("GUILDA:ResultCPF:InvalidMap"))
    end
    f_key = @(T) string(T.Kind) + "|" + string(T.Owner) + "|" + string(T.Name) + "|" + string(T.Bus);
    [lv, iv_col] = ismember(f_key(tab_map), f_key(obj.tab_variable));
    if ~all(lv)
        sv_label = string(tab_map.Label(~lv));
        error(msg("GUILDA:ResultCPF:UnknownVariable", join(sv_label(1:min(end,5)), ", ")))
    end
    rv = obj.rm_variable(Step, iv_col).';
end
