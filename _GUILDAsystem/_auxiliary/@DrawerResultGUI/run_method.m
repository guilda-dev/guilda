function run_method(obj, s_signature)
% Run a method of the result through the history and show what it returns.
%
% The code calls the method on the result variable, with the outputs named as in the
% signature ("s_text" for the text of a disp_* method). The options come from
% DrawerOptionDialog.ask, without Parent and the file of export, with the history so that
% defaults and choices on obj (e.g. obj.Type) are evaluated on the result; a method with no other
% input runs without the dialog, and a canceled dialog runs nothing. See DrawerResultGUI
% for the code of each kind of method and for h_parent. After a plot, the control panel
% follows its graph (show_plot_controls) and a plot that animates starts playing (autoplay). The button pressed is marked (light blue) and the
% pointer of the figure waits from the press to the end of the run, so a press shows at once.
    arguments (Input)
        obj
        s_signature (1,1) string  % Method in functionSignatures.json, e.g. "ResultPF.plot_voltage".
    end
    arguments (Output)
    end
    if ~isvalid(obj.h_plot)
        return
    end
    s_method = extractAfter(s_signature, ".");
    h_fig    = ancestor(obj.h_container, "figure");
    % Feedback at once: the button pressed is marked and the pointer waits until the run ends
    h_button = findall(obj.h_container, "Type", "uibutton", "Tag", "method");
    h_button = h_button(arrayfun(@(h) isequal(h.UserData, s_signature), h_button));
    if ~isempty(h_button)
        rv_back = h_button(1).BackgroundColor;
        h_button(1).BackgroundColor = tools.gui_palette().rv_header_subtext;
        c_button = onCleanup(@() set(h_button(isvalid(h_button)), "BackgroundColor", rv_back));
    end
    h_fig.Pointer = "watch";
    c_pointer = onCleanup(@() set(h_fig(isvalid(h_fig)), "Pointer", "arrow"));
    drawnow

    s_group  = "Result " + obj.s_variable;
    sct_sig = read_signatures().(replace(s_signature, ".", "_"));
    c_input = {};
    if isfield(sct_sig, "inputs")
        c_input = sct_sig.inputs;
    end
    if isstruct(c_input)
        c_input = num2cell(c_input);
    end
    sv_input = string(cellfun(@(a) a.name, c_input, "UniformOutput", false));
    c_output = {};
    if isfield(sct_sig, "outputs")
        c_output = sct_sig.outputs;
    end
    if isstruct(c_output)
        c_output = num2cell(c_output);
    end
    sv_output = reshape(string(cellfun(@(a) a.name, c_output, "UniformOutput", false)), 1, []);
    sv_output(sv_output == "varargout") = "s_text";    % the text of a disp_* method
    l_plot = startsWith(s_method, "plot_");
    l_disp = startsWith(s_method, "disp_");
    if l_disp
        sv_output = "s_text";
    end

    % The file of export: asked with uiputfile when someone can answer, a file of tempdir otherwise
    sv_exclude = ["obj", "Parent"];
    s_path = "";
    if s_method == "export" && ismember("filename", sv_input)
        sv_exclude(end+1) = "filename";
        s_name = obj.s_variable + ".csv";
        sct_in = c_input{sv_input == "filename"};
        if isfield(sct_in, "purpose")
            s_default = regexp(string(sct_in.purpose), "Default: (.*)\.$", "tokens", "once");
            try
                s_name = string(eval(s_default{1}));
            catch    % no default expression that can be evaluated here
            end
        end
        if h_fig.Visible && ~batchStartupOptionUsed
            [s_part, s_dir] = uiputfile("*" + regexp(s_name, "\.\w+$", "match", "once"), "Export " + s_signature, s_name);
            figure(h_fig)
            if isequal(s_part, 0)
                return
            end
            s_path = string(fullfile(s_dir, s_part));
        else
            s_path = string(fullfile(tempdir, s_name));
        end
    end

    % The code: the dialog when the method has other inputs, the plain call otherwise
    s_code = string(join(sv_output, ", "));
    if numel(sv_output) > 1
        s_code = "[" + s_code + "]";
    end
    if s_code ~= ""
        s_code = s_code + " = ";
    end
    s_code = s_code + obj.s_variable + "." + s_method + "();";
    if any(~ismember(sv_input, sv_exclude))
        try
            s_code = DrawerOptionDialog.ask(h_fig, s_signature, Object=obj.s_variable, ...
                Output=sv_output, Exclude=sv_exclude, History=obj.history);
        catch ME    % a form that cannot be made: the message instead of an error in a callback
            obj.h_text.Value = "Error in the options of " + s_signature + ":" + newline + string(ME.message);
            obj.h_tabs.SelectedTab = obj.h_text.Parent.Parent;
            return
        end
        if s_code == ""
            return
        end
    end
    s_quote = """" + replace(s_path, """", """""") + """";
    if s_path ~= ""    % the file first, before the options
        s_code = regexprep(s_code, "\.export\((\s*\))?", ".export(" + s_quote + "$1", "once");
        s_code = regexprep(s_code, "(\.export\(""(?:[^""]|"""")*"")(?!\s*\))", "$1, ", "once");
    end
    if l_plot && ismember("Parent", sv_input)
        if ~isempty(regexp(s_code, "\(\s*\)\s*;\s*$", "once"))
            s_code = regexprep(s_code, "\(\s*\)\s*;\s*$", "(Parent=h_parent);");
        else
            s_code = regexprep(s_code, "\)\s*;\s*$", ", Parent=h_parent);");
        end
        % the exported script draws in new figures: h_parent = [] before the first plot
        tab = obj.history.tab_entry;
        if ~any(tab.Status == "done" & tab.Code == "h_parent = [];")
            obj.history.run(s_group, "Draw the plots in new figures", "h_parent = [];");
        end
        delete(obj.h_plot.Children)
        obj.history.set_variable("h_parent", obj.h_plot);
    end
    if l_disp
        s_code = s_code + newline + "disp(s_text)";
    end

    [l_ok, s_detail] = obj.history.run(s_group, s_method, s_code);
    if ~isvalid(obj.h_plot)
        return
    end
    if ~l_ok
        obj.h_text.Value = "Error in " + s_signature + ":" + newline + s_detail;
        obj.h_tabs.SelectedTab = obj.h_text.Parent.Parent;
        if h_fig.Visible
            uialert(h_fig, s_detail, s_signature);
        end
        return
    end
    if l_plot
        obj.G_plot = [];
        c_value = arrayfun(@(s) obj.history.get_variable(s), sv_output, "UniformOutput", false);
        for i = 1:numel(c_value)
            if isa(c_value{i}, "GraphBase") && isscalar(c_value{i})
                obj.G_plot = c_value{i};
                break
            end
        end
        obj.show_plot_controls();
        obj.h_tabs.SelectedTab = obj.h_plot.Parent.Parent;
        obj.autoplay(c_value);
        return
    end
    % The text: the disp_* text without hyperlinks, or each output of a get_* or export
    sv_text = strings(0, 1);
    for s_out = sv_output
        value = obj.history.get_variable(s_out);
        if l_disp
            sv_text = [sv_text; regexprep(string(value(:)), "<a\s[^>]*>|</a>", "")];    %#ok<AGROW>
        else
            sv_text = [sv_text; s_out + " ="; ...
                string(formattedDisplayText(value, "SuppressMarkup", true))];        %#ok<AGROW>
        end
    end
    obj.h_text.Value = splitlines(join(sv_text, newline));
    obj.h_tabs.SelectedTab = obj.h_text.Parent.Parent;
end
