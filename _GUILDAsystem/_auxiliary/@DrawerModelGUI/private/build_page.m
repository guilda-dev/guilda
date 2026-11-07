function h_tab = build_page(h_tabs, drawer, sct_page)
% One tab of a page of gui_content, drawn by its s_type.
    arguments (Input)
        h_tabs    % Tab group.
        drawer    % DrawerModelGUI, which an "action" page renders again.
        sct_page  % Page: fields s_title, s_type, content, s_label.
    end
    arguments (Output)
        h_tab  % The tab.
    end
    h_tab  = uitab(h_tabs, "Title", string(sct_page.s_title), "Tag", string(sct_page.s_type));
    h_grid = uigridlayout(h_tab, [1 1]);
    switch string(sct_page.s_type)
        case "latex"
            sct_data = katex_data();
            sct_data.sv_math = string(sct_page.content(:));
            uihtml(h_grid, "HTMLSource", fullfile(fileparts(mfilename("fullpath")), "latex_page.html"), ...
                "Data", sct_data);
        case "image"
            uiimage(h_grid, "ImageSource", string(sct_page.content), "ScaleMethod", "fit");
        case "table"
            uitable(h_grid, "Data", sct_page.content, "ColumnEditable", false);
        case "action"
            h_grid.RowHeight   = {"fit"};
            h_grid.ColumnWidth = {"fit"};
            uibutton(h_grid, "Text", string(sct_page.s_label), ...
                "ButtonPushedFcn", @(src, ~) run_action(src, drawer, sct_page.content));
        otherwise
            uilabel(h_grid, "Text", "Unknown page type: " + string(sct_page.s_type));
    end
end

function run_action(h_button, drawer, f_action)
% Run the action, then draw the GUI again; an error shows an alert.
    try
        f_action();
    catch ME
        show_alert(h_button, ME.message, string(h_button.Text));
        return
    end
    drawer.render();
end

function sct_data = katex_data()
% The bundled KaTeX for latex_page.html: script, and style with the fonts as data URIs.
%
% uihtml reads files only in the folder of the HTML file and its subfolders, so the files of
% _GUILDAdoc/vendor/katex are passed through Data. They are read once per MATLAB session.
    arguments (Input)
    end
    arguments (Output)
        sct_data (1,1) struct  % Fields s_js (katex.min.js) and s_css (katex.min.css).
    end
    persistent sct_cache
    if isempty(sct_cache)
        s_root  = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
        s_katex = fullfile(s_root, "_GUILDAdoc", "vendor", "katex");
        s_css   = string(fileread(fullfile(s_katex, "katex.min.css")));
        % Each @font-face keeps only its woff2 file, embedded as a data URI.
        sv_font = unique(string(regexp(s_css, "(?<=url\(fonts/)[\w-]+(?=\.woff2\))", "match")).');
        for s_font = sv_font.'
            s_file = fullfile(s_katex, "fonts", s_font + ".woff2");
            i_file = fopen(s_file, "r");
            s_base64 = string(matlab.net.base64encode(fread(i_file, Inf, "uint8=>uint8")));
            fclose(i_file);
            s_uri = "url(data:font/woff2;base64," + s_base64 + ") format(""woff2"")";
            s_css = replace(s_css, "url(fonts/" + s_font + ".woff2) format(""woff2""),url(fonts/" + s_font ...
                + ".woff) format(""woff""),url(fonts/" + s_font + ".ttf) format(""truetype"")", s_uri);
        end
        sct_cache = struct("s_js", string(fileread(fullfile(s_katex, "katex.min.js"))), "s_css", s_css);
    end
    sct_data = sct_cache;
end
