function build_start(obj)
% Draw the start screen: the four ways to get a network, each run as code through the history.
%
% - Empty network (Tag "start_empty"): `net = PowerNetwork();`.
% - Sample network: the classes of `_GUILDAobject/+network` (folders @Name and files Name.m)
%   in a drop-down (Tag "start_sample"); Load (Tag "start_sample_load") runs
%   `net = network.<Name>();`.
% - Model folder: a model folder (Tag "start_folder", Browse... opens uigetdir when the
%   figure is visible); Load (Tag "start_folder_load") runs `net = PowerNetwork.import("<path>");`.
% - MATPOWER case: a case name or a .m/.mat file (Tag "start_matpower", Browse... opens uigetfile);
%   Load (Tag "start_matpower_load") runs `net = PowerNetwork.import_matpower("<case>");`.
%
% The loads run with a progress dialog. When the run ends with a network in `net`, the
% history listener (on_history_changed) replaces the start screen with the main layout; a
% failed run shows its message under the choices (Tag "start_message").
    arguments (Input)
        obj
    end
    arguments (Output)
    end
    sct_color = tools.gui_palette();
    h_start = uigridlayout(obj.h_root, [3 3], "RowHeight", {"1x", "fit", "1x"}, ...
        "ColumnWidth", {"1x", 680, "1x"}, "Tag", "start", "BackgroundColor", sct_color.rv_background);
    h_start.Layout.Row = 2;
    h_card = uigridlayout(h_start, [11 3], "RowHeight", repmat({"fit"}, 1, 11), ...
        "ColumnWidth", {"1x", "fit", "fit"}, "Padding", [24 20 24 20], "RowSpacing", 8, ...
        "BackgroundColor", sct_color.rv_card);
    h_card.Layout.Row = 2;
    h_card.Layout.Column = 2;
    % run_code is private: the local function gets it as a handle made here
    f_code = @(s_label, s_code) obj.run_code("Model building", s_label, s_code, Progress="Loading the network...");
    f_run = @(s_label, s_code) start_run(f_code, h_card, s_label, s_code);
    f_label = @(s_text, varargin) uilabel(h_card, "Text", s_text, "FontColor", sct_color.rv_text, ...
        "BackgroundColor", sct_color.rv_card, varargin{:});

    h = f_label("GUILDA", "FontSize", 22, "FontWeight", "bold", "FontColor", sct_color.rv_blue);
    h.Layout.Column = [1 3];
    h = f_label("Choose a network to start. The choice becomes the first line of the script.", "FontColor", sct_color.rv_subtext);
    h.Layout.Column = [1 3];

    % Empty network
    h = f_label("Empty network", "FontWeight", "bold");
    h.Layout.Column = [1 2];
    uibutton(h_card, "Text", "Create", "Tag", "start_empty", "BackgroundColor", sct_color.sct_kind.Bus, ...
        "FontColor", sct_color.rv_text, "ButtonPushedFcn", @(~, ~) f_run("New network", "net = PowerNetwork();"));

    % Sample networks: the classes of +network
    s_folder = fullfile(GUILDA.pwd(), "_GUILDAobject", "+network");
    a_file = dir(s_folder);
    sv_name = string({a_file.name});
    l_class = startsWith(sv_name, "@") & [a_file.isdir];
    l_file  = endsWith(sv_name, ".m") & ~[a_file.isdir];
    sv_sample = sort([extractAfter(sv_name(l_class), 1), regexprep(sv_name(l_file), "\.m$", "")]);
    h = f_label("Sample network", "FontWeight", "bold");
    h.Layout.Column = [1 3];
    h_sample = uidropdown(h_card, "Items", sv_sample, "Tag", "start_sample", ...
        "BackgroundColor", sct_color.rv_background, "FontColor", sct_color.rv_text);
    if ismember("IEEE9bus", sv_sample)
        h_sample.Value = "IEEE9bus";
    end
    h_sample.Layout.Column = [1 2];
    uibutton(h_card, "Text", "Load", "Tag", "start_sample_load", "BackgroundColor", sct_color.sct_kind.Bus, ...
        "FontColor", sct_color.rv_text, "ButtonPushedFcn", @(~, ~) f_run("Sample network " + string(h_sample.Value), ...
        "net = network." + string(h_sample.Value) + "();"));

    % Model folder and MATPOWER case: a path field, a browse button and a load button
    sm_path = ["Model folder", "start_folder", "Folder of a model (written by net.export)", ...
               "Import folder", "net = PowerNetwork.import(""%s"");"; ...
               "MATPOWER case", "start_matpower", "Case name (case14) or a .m / .mat file", ...
               "Import MATPOWER case", "net = PowerNetwork.import_matpower(""%s"");"];
    for k = 1:size(sm_path, 1)
        sv_row = sm_path(k, :);
        h = f_label(sv_row(1), "FontWeight", "bold");
        h.Layout.Column = [1 3];
        h_path = uieditfield(h_card, "text", "Tag", sv_row(2), "Placeholder", sv_row(3), ...
            "BackgroundColor", sct_color.rv_background, "FontColor", sct_color.rv_text);
        uibutton(h_card, "Text", "Browse...", "Tag", sv_row(2) + "_browse", "BackgroundColor", sct_color.rv_card, ...
            "FontColor", sct_color.rv_text, "ButtonPushedFcn", @(~, ~) browse_path(obj.h_figure, h_path, k == 1));
        uibutton(h_card, "Text", "Load", "Tag", sv_row(2) + "_load", "BackgroundColor", sct_color.sct_kind.Bus, ...
            "FontColor", sct_color.rv_text, "ButtonPushedFcn", @(~, ~) f_run(sv_row(4), ...
            sprintf(sv_row(5), replace(strtrim(string(h_path.Value)), """", """"""))));
    end
    h = f_label("", "Tag", "start_message", "WordWrap", "on", "FontColor", sct_color.rv_stale_text);
    h.Layout.Column = [1 3];
end

function start_run(f_code, h_card, s_label, s_code)
% Run a choice of the start screen; a failure writes its message under the choices.
    arguments (Input)
        f_code   % run_code of the app in the group "Model building": @(s_label, s_code).
        h_card   % Grid of the choices.
        s_label  % Label of the entry.
        s_code   % Code of the choice.
    end
    arguments (Output)
    end
    h_message = findobj(h_card, "Tag", "start_message");
    h_message.Text = "";
    [l_ok, s_detail] = f_code(s_label, s_code);
    if ~l_ok && isvalid(h_message)
        h_message.Text = "Could not load: " + regexprep(s_detail, " \(\d+\.\d+ s\)$", "");
    end
end

function browse_path(h_figure, h_path, l_folder)
% Choose a folder (uigetdir) or a case file (uigetfile) for a path field; only on a visible figure.
    arguments (Input)
        h_figure  % Figure of the app.
        h_path    % Path field.
        l_folder  % True for a folder, false for a .m or .mat file.
    end
    arguments (Output)
    end
    if ~h_figure.Visible || batchStartupOptionUsed
        return
    end
    if l_folder
        s_path = uigetdir(pwd, "Model folder");
        if isequal(s_path, 0)
            return
        end
    else
        [s_file, s_dir] = uigetfile({'*.m;*.mat', 'MATPOWER case (*.m, *.mat)'}, "MATPOWER case");
        if isequal(s_file, 0)
            return
        end
        s_path = fullfile(s_dir, s_file);
    end
    h_path.Value = s_path;
    figure(h_figure);
end
