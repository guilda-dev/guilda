function sm = gc_routes(comp, sm_before)
% Connections of the global controllers that control comp, read from the connection map
% of its network (rows "global": [GC tag, Source, Target], by Label). With sm_before (the
% connections before a local controller edit), shows the outputs whose targets changed as
% an INFO message (GUILDA:Component:GconRouteChanged), one message per global controller.
    arguments (Input)
        comp                     % Component whose local controllers are edited.
        sm_before (:,3) string = strings(0,3)   % Connections before the edit (gc_routes(comp)).
    end
    arguments (Output)
        sm (:,3) string          % Connections now: [GC tag, Source, Target].
    end
    sm = strings(0,3);
    if isempty(comp.a_Bus) || isempty(comp.a_Bus.a_PowerNetwork)
        return
    end
    net = comp.a_Bus.a_PowerNetwork;
    lv_gc = cellfun(@(gc) any(cellfun(@(u) u == comp, gc.controlledUnits)), net.a_GlobalController);
    if ~any(lv_gc)
        return
    end
    [tab, ~, ~, tab_c] = net.get_variable_map();
    lv = tab_c.Kind == "global" & ismember(tab.Owner(max(tab_c.SourceIndex,1)), string(net.a_GlobalController(lv_gc)));
    sm = [tab.Owner(tab_c.SourceIndex(lv)), tab_c.Source(lv), tab_c.Target(lv)];
    if nargin < 2
        return
    end

    % The sources of the controllers of comp whose set of targets changed
    sv_src = unique([sm(:,2); sm_before(:,2)], "stable");
    for s_gc = reshape(unique([sm(:,1); sm_before(:,1)], "stable"), 1, [])
        sv_line = strings(0,1);
        for s_src = reshape(sv_src, 1, [])
            sv_new = sm(sm(:,1) == s_gc & sm(:,2) == s_src, 3);
            sv_old = sm_before(sm_before(:,1) == s_gc & sm_before(:,2) == s_src, 3);
            if isempty(sv_new) && isempty(sv_old) || isequal(sort(sv_new), sort(sv_old))
                continue
            end
            if isempty(sv_new)
                sv_line(end+1,1) = s_src + " -> (no input)"; %#ok<AGROW>
            else
                sv_line(end+1,1) = s_src + " -> " + join(sv_new, ", "); %#ok<AGROW>
            end
        end
        if ~isempty(sv_line)
            show_msg("info", "GUILDA:Component:GconRouteChanged", s_gc, join(sv_line, "; "))
        end
    end
end
