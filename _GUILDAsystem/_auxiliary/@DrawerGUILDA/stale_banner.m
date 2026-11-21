function h_banner = stale_banner(obj, h_grid, i_row, s_group)
% Banner in a row of a grid that asks for net.initialize() while the network is stale.
%
% The banner (Tag "stale_banner") spans all columns of row i_row of h_grid. While the
% network is stale it shows the stale tags (Tag "stale_text") and the button
% "Run initialize" (Tag "initialize"), which runs `net.initialize();` through the history
% (initialize shows its own progress, so the app opens no progress dialog); otherwise the
% height of the row is 0. It is updated on every event Changed of the history until it is
% deleted.
    arguments (Input)
        obj
        h_grid  (1,1) matlab.ui.container.GridLayout  % Grid of the tab.
        i_row   (1,1) double {mustBeInteger, mustBePositive}  % Row of the banner in h_grid.
        s_group (1,1) string                          % Group of the initialize entry.
    end
    arguments (Output)
        h_banner  % Grid layout of the banner. <@Type> matlab.ui.container.GridLayout
    end
    sct_color = tools.gui_palette();
    h_banner = uigridlayout(h_grid, [1 2], "ColumnWidth", {"1x", "fit"}, "Padding", [10 6 10 6], ...
        "Tag", "stale_banner", "BackgroundColor", sct_color.rv_stale_back);
    h_banner.Layout.Row = i_row;
    h_banner.Layout.Column = unique([1 numel(h_grid.ColumnWidth)]);
    h_text = uilabel(h_banner, "Text", "", "Tag", "stale_text", "WordWrap", "on", ...
        "FontColor", sct_color.rv_stale_text, "BackgroundColor", sct_color.rv_stale_back);
    uibutton(h_banner, "Text", "Run initialize", "Tag", "initialize", "FontWeight", "bold", ...
        "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_card, ...
        "ButtonPushedFcn", @(~, ~) obj.run_code(s_group, "Initialize", "net.initialize();"));
    h_listener = listener(obj.history, "Changed", @(~, ~) update_banner(h_banner, h_text, obj.history));
    h_banner.DeleteFcn = @(~, ~) delete(h_listener);
    update_banner(h_banner, h_text, obj.history);
end

function update_banner(h_banner, h_text, history)
% Show the banner with the stale tags of net, or set the height of its row to 0.
    arguments (Input)
        h_banner  % Grid layout of the banner.
        h_text    % Label of the stale tags.
        history   % History of the app.
    end
    arguments (Output)
    end
    if ~isvalid(h_banner) || (~isempty(history.tab_entry) && history.tab_entry.Status(end) == "run")
        return
    end
    sv_stale = strings(1, 0);
    try
        net = history.get_variable("net");
        sct_stale = net.sct_stale;
        sv_stale = string(fieldnames(sct_stale)).';
        sv_stale = sv_stale(arrayfun(@(s) ~isempty(sct_stale.(s)), sv_stale));
    catch    % no network
    end
    h_grid = h_banner.Parent;
    if isempty(sv_stale)
        h_grid.RowHeight{h_banner.Layout.Row} = 0;
        h_banner.Visible = "off";
    else
        h_text.Text = "The network is stale (" + join(sv_stale, ", ") + "). Run initialize before the analysis.";
        h_grid.RowHeight{h_banner.Layout.Row} = "fit";
        h_banner.Visible = "on";
    end
end
