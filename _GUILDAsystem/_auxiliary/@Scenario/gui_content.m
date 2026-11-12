function sct_page = gui_content(obj)
% Pages of the GUI of a scenario: "Disturbances" and "Settings", then the pages of LayerPackage.
%
% - "Disturbances" ("table"): tab_disturbance, one row per disturbance, with the lists of
%   tags and names and the values (constants, time series [t, v]) shown as text.
% - "Settings" ("table"): Time [s] and Description.
%
% A scenario has no parameters, so the GUI shows no Parameter tab.
%
% See also LayerPackage.gui, LayerPackage.gui_content
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type and content.
    end
    tab = obj.tab_disturbance;
    tab_show = table();
    for s_var = string(tab.Properties.VariableNames)
        x = tab.(s_var);
        if iscell(x)
            x = string(cellfun(@as_text, x, "UniformOutput", false));
        elseif ~isstring(x)
            x = string(arrayfun(@(k) mat2str(x(k,:)), (1:height(tab)).', 'UniformOutput', false));
        end
        tab_show.(s_var) = x;
    end
    Item  = ["Time [s]"; "Description"];
    Value = [string(mat2str(obj.Time)); obj.Description];
    sct_page = [struct("s_title","Disturbances", "s_type","table", "content",tab_show); ...
        struct("s_title","Settings", "s_type","table", "content",table(Item, Value)); ...
        gui_content@LayerPackage(obj)];
end

function s = as_text(x)
% One cell of tab_disturbance as text: a list joined by ", ", numbers as mat2str
    if isempty(x)
        s = "";
    elseif isstring(x)
        s = join(x(:).', ", ");
    else
        s = string(mat2str(x));
    end
end
