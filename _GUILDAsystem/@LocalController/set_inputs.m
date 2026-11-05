function set_inputs(obj, sv_name)
% Set the input names sv_u after "Xall" / "Yall" are expanded. A controller that
% uses "Xall" or "Yall" in sv_u overrides this (sv_u is defined by the subclass).
%
% <@Group> Hooks for subclasses
    arguments (Input)
        obj
        sv_name (:,1) string   % Input names with "Xall" / "Yall" expanded.
    end
    error(msg("GUILDA:LocalController:ReservedInputNoOverride", class(obj)))
end
