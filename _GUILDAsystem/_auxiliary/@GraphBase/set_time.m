function set_time(obj, t)
% Show the sample nearest to time t, in this graph and in the graphs linked to it.
%
% t is a time in seconds, or for samples named by the data (s_sampleName, e.g. "Step") the
% value of a sample in the same units as rv_t (e.g. a step number).
%
% Each linked graph shows the sample nearest to t of its own times. The links are followed
% through (a graph linked to a linked graph moves too), and every graph is drawn once, so
% links in a ring do not loop. A linked graph whose axes were deleted is skipped. The
% playback bar of every graph drawn shows its sample.
%
% After all of them are drawn, each graph drawn raises TimeChanged and calls its
% TimeChangedFcn as fcn(G, data), with data a GraphTimeEventData (Time and Index of the
% sample it shows), in the order they were drawn. While these callbacks run, the graphs
% of this set_time are fixed: a set_time called from a callback (on any graph) leaves them
% as they are and raises nothing on them, as the links draw each graph once, so a callback
% that moves a linked graph does not loop. Other graphs move and raise TimeChanged as usual.
%
% <@Examples>
% ```matlab
% G = res.plot_spring_model();
% G.TimeChangedFcn = @(G, data) title(G.ax, "sample " + data.Index);
% G.set_time(1.2);
% ```
    arguments (Input)
        obj
        t (1,1) double  % Time to show [s], or the value of a sample named by the data (e.g. a step).
    end
    if ~all(isgraphics(obj.ax))
        error(msg("GUILDA:GraphBase:NoAxes", class(obj)));
    end
    c_todo  = {obj};
    c_done  = {};
    c_drawn = {};
    while ~isempty(c_todo)
        G = c_todo{1};
        c_todo(1) = [];
        if any(cellfun(@(g) g == G, c_done))
            continue
        end
        c_done{end+1} = G; %#ok<AGROW>
        if G.l_timeFixed
            continue
        end
        G.c_link = G.c_link(cellfun(@(g) isvalid(g), G.c_link));
        if ~all(isgraphics(G.ax))
            continue
        end
        [~, k] = min(abs(G.rv_t - t));
        G.i_time = k;
        G.update_scene(k);
        G.apply_selection();
        G.refresh_bar();
        c_drawn{end+1} = G; %#ok<AGROW>
        c_todo = [c_todo, G.c_link]; %#ok<AGROW>
    end

    % TimeChanged of every graph drawn, with these graphs fixed until all callbacks return
    for i = 1:numel(c_drawn)
        c_drawn{i}.l_timeFixed = true;
    end
    err = [];
    try
        for i = 1:numel(c_drawn)
            G = c_drawn{i};
            if ~isvalid(G)
                continue
            end
            data = GraphTimeEventData(G.rv_t(G.i_time), G.i_time);
            notify(G, "TimeChanged", data);
            if ~isempty(G.TimeChangedFcn)
                G.TimeChangedFcn(G, data);
            end
        end
    catch err
    end
    for i = 1:numel(c_drawn)
        if isvalid(c_drawn{i})
            c_drawn{i}.l_timeFixed = false;
        end
    end
    if ~isempty(err)
        rethrow(err);
    end
end
