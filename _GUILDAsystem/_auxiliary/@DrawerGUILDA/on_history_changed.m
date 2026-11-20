function on_history_changed(obj)
% Follow the history: when an entry ends, update the tabs and draw the diagram again.
%
% On the start screen, an entry that ends with a network in `net` replaces it with the main
% layout. Afterwards each ended entry (done or failed: a failed run may have changed part of
% the network) marks all tabs out of date (n_change), calls the hook f_changed of the
% active tab and then redraw, which draws its diagram. A hidden tab gets f_changed and its
% drawing on its next show (show_tab). In a visible figure (outside matlab -batch) redraw
% runs from a single-shot timer (h_timer, 0.05 s) right after the run, so the GUI that ran
% the code draws itself first, and the runs ended before the timer fires are drawn once; a
% hidden figure (tests) draws at once.
    arguments (Input)
        obj
    end
    arguments (Output)
    end
    if ~isvalid(obj) || ~isvalid(obj.h_figure)
        return
    end
    tab = obj.history.tab_entry;
    if isempty(tab) || tab.Status(end) == "run"
        return
    end
    if obj.s_active == ""
        try
            net = obj.history.get_variable("net");
        catch    % no network yet
            return
        end
        if isa(net, "PowerNetwork") && isscalar(net)
            obj.build_main();
        end
        return
    end
    obj.n_change = obj.n_change + 1;    % every diagram is out of date; redraw draws the active one
    i_tab = find([obj.sct_tab.s_key] == obj.s_active, 1);
    obj.sct_tab(i_tab).n_changed = obj.n_change;
    if ~isempty(obj.sct_tab(i_tab).f_changed)
        obj.sct_tab(i_tab).f_changed();
    end
    if ~obj.h_figure.Visible || batchStartupOptionUsed
        obj.redraw();
        return
    end
    % Visible app: the drawing follows by a single-shot timer, so the GUI that ran the code
    % (e.g. the model GUI, which renders after the run) responds first, and the runs of a
    % burst are drawn once
    if obj.h_timer.Running == "off"
        start(obj.h_timer);
    end
end
