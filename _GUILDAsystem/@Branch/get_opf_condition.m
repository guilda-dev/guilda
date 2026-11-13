function varargout = get_opf_condition(obj, opt)
% Return the optimal-power-flow condition of the branch.
%
% The table holds exactly what net.calculate_optimal_powerflow and net.build_opf_problem
% use for this branch (one row, row name = tag):
%
% - From, To: tags of the end buses (a_Bus{1}, a_Bus{2}).
% - Y: 2x2 admittance matrix [pu] of get_admittance_matrix (a 1x2x2 page).
% - X, tap, phase: tab_parameter.dynamics, for "DC OPF"; tap 1 and phase 0 when absent,
%   NaN or a zero tap.
% - Pmax, Qmax, Vargmax, Imax, Smax: tab_parameter.operation.
%
% With Display=true (default) the table is printed under the heading "Branch", without
% the column Y (the returned table keeps it); with no output nothing is returned.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.a_Branch{1}.get_opf_condition();                   % print the table
% tab_branch = net.a_Branch{1}.get_opf_condition(Display=false);
% Y = squeeze(tab_branch.Y(1,:,:));                      % 2x2 admittance matrix
% ```
%
% See also PowerNetwork.get_opf_condition, Bus.get_opf_condition
%
% <@Group> OPF
    arguments (Input)
        obj
        opt.Display (1,1) logical = true   % Print the table.
    end
    arguments (Output, Repeating)
        varargout   % tab_branch: one-row table of the branch.
    end
    tp = obj.tab_parameter;
    % X, tap, phase of "DC OPF" as in MATPOWER: tap 1 and phase 0 for lines (absent, NaN or a zero tap)
    sv_dyn = string(tp.dynamics.Properties.VariableNames);
    X = NaN;  tap = 1;  phase = 0;
    if ismember("X", sv_dyn)
        X = tp.dynamics.X;
    end
    if ismember("tap", sv_dyn) && ~isnan(tp.dynamics.tap) && tp.dynamics.tap ~= 0
        tap = tp.dynamics.tap;
    end
    if ismember("phase", sv_dyn) && ~isnan(tp.dynamics.phase)
        phase = tp.dynamics.phase;
    end
    ope = tp.operation;
    tab_branch = [table(string(obj.a_Bus{1}), string(obj.a_Bus{2}), ...
                        reshape(obj.get_admittance_matrix, 1, 2, 2), 'VariableNames', ["From","To","Y"]), ...
                  array2table([X, tap, phase, ope.Pmax, ope.Qmax, ope.Vargmax, ope.Imax, ope.Smax], ...
                              "VariableNames", ["X","tap","phase","Pmax","Qmax","Vargmax","Imax","Smax"])];
    tab_branch.Properties.RowNames = string(obj);

    if opt.Display
        fprintf("%s\n%s\n", "Branch", formattedDisplayText(removevars(tab_branch, "Y")));
    end
    if ~opt.Display || nargout > 0
        varargout = {tab_branch};
    end
end
