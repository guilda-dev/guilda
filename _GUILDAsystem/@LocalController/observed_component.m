function comp = observed_component(obj)
% The component the controller observes: its parent, or for a nested
% controller (e.g. a PSS under an AVR) the component above them
%
% <@Group> Internal helpers
    arguments (Input)
        obj
    end
    arguments (Output)
        comp   % Observed Component.
    end
    comp = obj.a_Component;
    while isa(comp, "LocalController")
        comp = comp.a_Component;
    end
end
