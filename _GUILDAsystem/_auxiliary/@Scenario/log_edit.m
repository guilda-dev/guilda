function log_edit(obj, log, tag) %#ok<INUSD>
% Do nothing: a scenario is not model data, so editing it makes nothing stale.
%
% Overrides LayerPackage.log_edit, which a rename (set.s_tag) calls: renaming a scenario
% reaches no handle_edit of the network (no stale tag, no revision).
    arguments (Input)
        obj
        log (1,1) string   % What was edited (unused).
        tag (1,1) string   % Kind of edit (unused).
    end
end
