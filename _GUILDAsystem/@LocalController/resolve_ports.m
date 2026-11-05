function resolve_ports(obj, comp)
% Called by resolve_observe with the observed component before the inputs
% are resolved: a controller whose ports depend on the component (e.g. the
% inputs of the component it drives) sets them here. Does nothing by default.
%
% <@Group> Hooks for subclasses
    arguments (Input)
        obj
        comp   % Observed component.
    end
end
