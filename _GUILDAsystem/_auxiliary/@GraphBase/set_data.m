function set_data(obj, sct_data)
% Replace the data of the graph and draw it again.
%
% sct_data has the same contract as the data of the constructor of the subclass. The
% appearance set by set_style or by the vector properties is kept for the elements that
% are still there (the same tag and kind); new elements get the defaults of the data. The
% sample shown is the one nearest to the time shown before. The selection keeps the tags
% that are still there. The defaults of reset_style of an element that was there stay
% those of the data it came with. The linked graphs do not move. The panel of
% show_controls stays. The slider of the playback bar takes the new samples; the bar
% appears or goes when the number of samples crosses two.
%
% <@Examples>
% ```matlab
% G = res1.plot_spring_model();
% G.set_style("B001", Color="r");
% res2 = net.simulate("fault2", Time=[0, 5]);
% sct  = res2.plot_spring_model(Parent=axes(figure("Visible", "off"))).sct_data;
% G.set_data(sct);                      % B001 stays red
% ```
    arguments (Input)
        obj
        sct_data (1,1) struct  % Data of the graph (see the constructor of the subclass).
    end
    tab_old = obj.tab_element;
    sct_map = obj.style_properties();
    t_old   = obj.rv_t(obj.i_time);
    % Appearance of the elements before the change, property by property, with the kinds
    % that use it (one property may serve several kinds, e.g. SeriesColor of GraphChart)
    sct_old = struct();
    for s_kind = string(fieldnames(sct_map))'
        for s_opt = string(fieldnames(sct_map.(s_kind)))'
            s_prop = sct_map.(s_kind).(s_opt);
            if ~isfield(sct_old, s_prop)
                sct_old.(s_prop) = struct("sv_kind", s_kind, "value", obj.(s_prop));
            elseif ~any(sct_old.(s_prop).sv_kind == s_kind)
                sct_old.(s_prop).sv_kind(end+1) = s_kind;
            end
        end
    end

    obj.sct_pltPrevious = obj.sct_plt;     % create_scene may reuse the objects of the drawing before
    obj.sct_plt = struct.empty;            % the setters draw nothing until the scene exists
    c_previous = onCleanup(@() clear_previous(obj));
    obj.load_data(sct_data);

    % Copy the old appearance and defaults to the elements that are still there
    tab_new = obj.tab_element;
    sct_def = struct();
    for s_prop = string(fieldnames(sct_old))'
        v_new = obj.(s_prop);
        v_def = v_new;
        for s_kind = sct_old.(s_prop).sv_kind
            if isfield(obj.sct_styleDefault, s_prop)
                v_def = copy_by_tag(v_def, obj.sct_styleDefault.(s_prop), tab_old, tab_new, s_kind);
            end
            v_new = copy_by_tag(v_new, sct_old.(s_prop).value, tab_old, tab_new, s_kind);
        end
        sct_def.(s_prop) = v_def;
        obj.(s_prop) = v_new;
    end
    obj.sct_styleDefault = sct_def;
    obj.Selection = obj.Selection(ismember(obj.Selection, tab_new.Tag));

    obj.create_scene();
    obj.sct_pltPrevious = struct.empty;
    [~, k] = min(abs(obj.rv_t - t_old));
    obj.i_time = k;
    obj.update_scene(k);
    obj.apply_selection();
    obj.refresh_controls();
    obj.refresh_bar();
end


function v_new = copy_by_tag(v_new, v_old, tab_old, tab_new, s_kind)
% Rows of v_new of the elements of a kind that were there before, taken from v_old.
    arguments (Input)
        v_new                % New value of an appearance vector.
        v_old                % Old value.
        tab_old table        % Elements before.
        tab_new table        % Elements after.
        s_kind (1,1) string  % Kind of the vector.
    end
    arguments (Output)
        v_new  % New value with the old rows copied.
    end
    iv_old = find(tab_old.Kind == s_kind);
    iv_new = find(tab_new.Kind == s_kind);
    [l_keep, i_loc] = ismember(tab_new.Tag(iv_new), tab_old.Tag(iv_old));
    iv_from = tab_old.Index(iv_old(i_loc(l_keep)));
    iv_to   = tab_new.Index(iv_new(l_keep));
    iv_ok   = iv_from <= size(v_old, 1) & iv_to <= size(v_new, 1);
    v_new(iv_to(iv_ok), :) = v_old(iv_from(iv_ok), :);
end


function clear_previous(obj)
% Drop the drawing before (onCleanup of set_data, also after an error).
    arguments (Input)
        obj  % The graph.
    end
    if isvalid(obj)
        obj.sct_pltPrevious = struct.empty;
    end
end

