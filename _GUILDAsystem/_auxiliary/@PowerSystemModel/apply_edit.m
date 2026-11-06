function apply_edit(obj, s_target)
% Rebuild what the layer derives from its parameters, for one target.
% check_edit calls it with "odefcn" on every layer at the start of an analysis.
% "odefcn": the cached f_* function handles; Component, LocalController and
% GlobalController override this to build them from the current parameters and
% network frequency. Other layers have nothing to rebuild.
    arguments (Input)
        obj
        s_target (1,1) string  % What to rebuild: "odefcn" (the f_* handles).
    end
end
