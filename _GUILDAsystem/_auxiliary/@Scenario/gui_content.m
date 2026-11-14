function sct_page = gui_content(obj)
% Pages of the GUI of a scenario: "Events", "Offsets", "Inputs" and "Settings", then the pages of LayerPackage.
%
% - "Events", "Offsets", "Inputs" ("table"): tab_event, tab_offset and tab_input, with the
%   lists of names and the values (constants, time series [t, v]) shown as text.
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
    c_page = {"Events", obj.tab_event; "Offsets", obj.tab_offset; "Inputs", obj.tab_input};
    sct_page = struct("s_title", cell(0,1), "s_type", cell(0,1), "content", cell(0,1));
    for i = 1:size(c_page, 1)
        tab = c_page{i,2};
        tab_show = table();
        for s_var = string(tab.Properties.VariableNames)
            x = tab.(s_var);
            if iscell(x)
                % a list joined by ", ", numbers as mat2str
                c_text = cell(size(x));
                for k = 1:numel(x)
                    if isempty(x{k})
                        c_text{k} = "";
                    elseif isstring(x{k})
                        c_text{k} = join(x{k}(:).', ", ");
                    else
                        c_text{k} = string(mat2str(x{k}));
                    end
                end
                x = reshape(string(c_text), [], 1);
            elseif ~isstring(x)
                x = string(arrayfun(@(k) mat2str(x(k,:)), (1:height(tab)).', 'UniformOutput', false));
            end
            tab_show.(s_var) = x;
        end
        sct_page(end+1, 1) = struct("s_title", c_page{i,1}, "s_type", "table", "content", tab_show); %#ok<AGROW>
    end
    Item  = ["Time [s]"; "Description"];
    Value = [string(mat2str(obj.Time)); obj.Description];
    sct_page = [sct_page; ...
        struct("s_title","Settings", "s_type","table", "content",table(Item, Value)); ...
        gui_content@LayerPackage(obj)];
end
