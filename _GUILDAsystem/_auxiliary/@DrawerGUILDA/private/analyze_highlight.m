function [l_new, res] = analyze_highlight(history, s_call, s_variable, res_opened, h_run, h_analyze)
% Style Run and Analyze result of a tab: Analyze result is the filled primary button while a new result is unopened.
%
% The result is the variable s_variable of the history. It is new while it is a scalar
% ResultBase, the last ended entry of the history whose code starts with s_call (the call
% of the tab, e.g. "[res_pf, flag_pf] = net.calculate_powerflow(") is done, and it is not
% res_opened (the result last opened from the tab). Then Analyze result is filled with the
% logo blue, bold with white text, and Run takes the plain style of the other buttons; else
% Run is the filled one and Analyze result plain. Analyze result is enabled while the
% variable holds a scalar ResultBase. Only properties that change are set.
    arguments (Input)
        history                    % History of the app.
        s_call (1,1) string        % Start of the code of the call of the tab.
        s_variable (1,1) string    % Result variable, e.g. "res_pf".
        res_opened                 % Result last opened from the tab, or [].
        h_run                      % Run button of the tab.
        h_analyze                  % Analyze result button of the tab.
    end
    arguments (Output)
        l_new (1,1) logical  % A new result is unopened (Analyze result is highlighted).
        res                  % The result variable when it holds a scalar ResultBase, else [].
    end
    try
        res = history.get_variable(s_variable);
    catch    % no result yet
        res = [];
    end
    if ~(isa(res, "ResultBase") && isscalar(res) && isvalid(res))
        res = [];
    end
    l_new = false;
    if ~isempty(res) && ~(isa(res_opened, "ResultBase") && isscalar(res_opened) && isvalid(res_opened) && res_opened == res)
        tab = history.tab_entry;
        i_last = find(startsWith(tab.Code, s_call) & tab.Status ~= "run", 1, "last");
        l_new = ~isempty(i_last) && tab.Status(i_last) == "done";
    end
    sct_color = tools.gui_palette();
    sct_primary = struct("BackgroundColor", sct_color.rv_blue, "FontColor", sct_color.rv_header_text, "FontWeight", "bold");
    sct_plain   = struct("BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text, "FontWeight", "normal");
    c_style = {sct_primary, sct_plain};
    if l_new
        c_style = c_style([2 1]);
    end
    h_button = [h_run, h_analyze];
    for i = 1:2
        for s_prop = ["BackgroundColor", "FontColor", "FontWeight"]
            if ~isequal(h_button(i).(s_prop), c_style{i}.(s_prop))
                h_button(i).(s_prop) = c_style{i}.(s_prop);
            end
        end
    end
    l_enable = ~isempty(res);
    if h_analyze.Enable ~= l_enable
        h_analyze.Enable = l_enable;
    end
end
