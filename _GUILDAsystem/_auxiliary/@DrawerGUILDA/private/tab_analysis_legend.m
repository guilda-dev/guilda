function s_legend = tab_analysis_legend(history, s_variable, s_class, s_after, s_before)
% Legend of the diagram of an analysis tab: s_after while the result variable holds a result of s_class, else s_before.
%
% The hook f_legend of the CPF tab (tab_list); it follows the same rule as its diagram
% function (the LoadBus buses of the last run selected).
    arguments (Input)
        history                 % History of the app.
        s_variable (1,1) string % Result variable of the tab, e.g. "res_pf".
        s_class (1,1) string    % Class of the result, e.g. "ResultPF".
        s_after (1,1) string    % Legend after a run.
        s_before (1,1) string   % Legend before a run.
    end
    arguments (Output)
        s_legend (1,1) string   % One line for the info strip.
    end
    s_legend = s_before;
    try
        res = history.get_variable(s_variable);
    catch    % no run yet
        return
    end
    if isa(res, s_class) && isscalar(res)
        s_legend = s_after;
    end
end
