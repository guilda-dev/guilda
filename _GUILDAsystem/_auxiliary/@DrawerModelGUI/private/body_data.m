function sct_data = body_data(a_target, sct_page, s_expr, s_selected)
% Data of the body of the model GUI (model_body.html): the Parameter tab and the pages of gui_content.
%
% The body is one uihtml (Tag "body"), so that a render sends all its tables in one message
% instead of writing each uitable (a uitable write costs the figure 40-60 ms). Fields:
%
% - tabs (cell): one struct per tab with title and type:
%   - "parameter" (a model with a_Parameter, not a Scenario): message (the note on the Docs)
%     and panels, one per container of a_Parameter, in its order: tag, index (in
%     a_Parameter), vertical, editable and table. A container of one row whose parameters
%     are all scalars (numeric, logical or string) is vertical: one row per parameter with
%     its full name and the column Value; two such panels stand side by side. Any other
%     container has one column per parameter.
%   - "table" (a page of gui_content): table, and events (true for an event table of a
%     Scenario in the tree of the history, whose rows can be removed).
%   - any other type: message "Unknown page type: ...".
% - table: cols, kinds (per column: number, logical, text, or fixed for a value that is not
%   edited in a cell), rows (a cell of rows, each a cell of texts, or logicals for the
%   logical cells), rownames, and rowkinds (the kind of each row of a vertical table).
% - selected: the title of the tab shown (s_selected when the model has it, else the first).
% - color: the colors of tools.gui_palette as "#RRGGBB".
%
% Numbers are written with 6 significant digits (complex as a+bi, several columns as a
% row vector); a NaN is "NaN".
    arguments (Input)
        a_target              % Model shown.
        sct_page (:,1) struct % Pages of gui_content: fields s_title, s_type and content.
        s_expr (1,1) string   % Expression of the model shown ("": not editable, a model outside the tree of the history).
        s_selected (1,1) string = ""  % Title of the tab chosen before ("": the first tab).
    end
    arguments (Output)
        sct_data (1,1) struct  % Data of the uihtml.
    end
    c_tab = {};
    if isprop(a_target, "a_Parameter")    % a Scenario has no parameters
        a_para = a_target.a_Parameter;
        c_panel = cell(1, numel(a_para));
        for k = 1:numel(a_para)
            p = a_para{k};
            tab = p.tab_parameter;
            l_vertical = height(tab) == 1 && width(tab) > 0 && all(varfun(@(v) size(v, 2) == 1 ...
                && (isnumeric(v) || islogical(v) || isstring(v)), tab, "OutputFormat", "uniform"));
            sct_table = table_data(tab);
            if l_vertical    % Name/Value: one row per parameter
                sct_table = struct("cols", {{'Value'}}, "kinds", {{''}}, "rows", {reshape(sct_table.rows{1}, [], 1)}, ...
                    "rownames", {sct_table.cols}, "rowkinds", {sct_table.kinds});
                sct_table.rows = cellfun(@(v) {v}, sct_table.rows, "UniformOutput", false);
            end
            c_panel{k} = struct("tag", string(p.s_tag), "index", k, "vertical", l_vertical, ...
                "editable", s_expr ~= "", "table", sct_table);
        end
        c_tab{end+1} = struct("title", "Parameter", "type", "parameter", ...
            "message", "See Docs for the meaning of each parameter and the model.", "panels", {c_panel});
    end
    for k = 1:numel(sct_page)
        s_type = string(sct_page(k).s_type);
        sct_tab = struct("title", string(sct_page(k).s_title), "type", s_type);
        if s_type == "table"
            content = sct_page(k).content;
            if ~istable(content)
                content = array2table(content);
            end
            sct_tab.table = table_data(content);
            % The event tables of a Scenario (with a Tag column): a row can be removed
            sct_tab.events = isa(a_target, "Scenario") && s_expr ~= "" && ismember("Tag", content.Properties.VariableNames);
        else
            sct_tab.message = "Unknown page type: " + s_type;
        end
        c_tab{end+1} = sct_tab; %#ok<AGROW>
    end
    sv_title = string(cellfun(@(t) t.title, c_tab, "UniformOutput", false));
    if ~any(sv_title == s_selected)
        s_selected = "";
        if ~isempty(sv_title)
            s_selected = sv_title(1);
        end
    end
    sct_color = tools.gui_palette();
    f_hex = @(rv) "#" + join(string(dec2hex(round(255*rv), 2)), "");
    sct_hex = struct("background", f_hex(sct_color.rv_background), "card", f_hex(sct_color.rv_card), ...
        "stripe", f_hex(sct_color.rv_stripe), "text", f_hex(sct_color.rv_text), ...
        "subtext", f_hex(sct_color.rv_subtext), "blue", f_hex(sct_color.rv_blue), ...
        "border", f_hex(0.88*sct_color.rv_stripe), "select", f_hex(sct_color.sct_kind.Bus));
    sct_data = struct("tabs", {c_tab}, "selected", s_selected, "color", sct_hex);
end

function sct_table = table_data(tab)
% Columns, kinds and rows of a table as texts (one column per variable).
    arguments (Input)
        tab table  % Table to show.
    end
    arguments (Output)
        sct_table (1,1) struct  % cols, kinds, rows, rownames, rowkinds.
    end
    sv_name = string(tab.Properties.VariableNames);
    n_row = height(tab);
    n_var = numel(sv_name);
    c_kind = cell(1, n_var);
    c_cell = cell(n_row, n_var);
    for j = 1:n_var
        x = tab.(sv_name(j));
        if islogical(x) && size(x, 2) == 1
            c_kind{j} = 'logical';
            c_cell(:, j) = num2cell(x);
        elseif isnumeric(x)
            c_kind{j} = 'number';
            for i = 1:n_row    % 6 significant digits, a+bi for a complex number, [a b] for several
                sv = compose("%.6g", real(double(x(i, :))));
                if ~isreal(x)
                    sv = sv + compose("%+.6gi", imag(double(x(i, :))));
                end
                c_cell{i, j} = char(join(sv, " "));
                if size(x, 2) ~= 1
                    c_cell{i, j} = ['[' c_cell{i, j} ']'];
                end
            end
        elseif (isstring(x) || iscellstr(x) || ischar(x)) && size(x, 2) == 1
            c_kind{j} = 'text';
            sv = string(x);
            sv(ismissing(sv)) = "";
            c_cell(:, j) = cellstr(sv);
        else    % a cell, a datetime, a categorical, several columns of text...: shown, not edited
            c_kind{j} = 'fixed';
            for i = 1:n_row
                try
                    c_cell{i, j} = char(join(string(x(i, :)), ", "));
                catch    % no text for it
                    c_cell{i, j} = ['<' class(x) '>'];
                end
            end
        end
    end
    c_rowName = {};
    if ~isempty(tab.Properties.RowNames)
        c_rowName = reshape(tab.Properties.RowNames, 1, []);
    end
    c_row = cell(1, n_row);
    for i = 1:n_row
        c_row{i} = c_cell(i, :);
    end
    sct_table = struct("cols", {cellstr(sv_name)}, "kinds", {c_kind}, "rows", {c_row}, ...
        "rownames", {c_rowName}, "rowkinds", {{}});
end

