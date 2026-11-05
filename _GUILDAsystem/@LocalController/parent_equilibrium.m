function val = parent_equilibrium(obj, s_prop)
% Read the parent's (a Component, or an AVR for a PSS) equilibrium.
% Kept out of the get methods: MATLAB reads the stored value when a
% get method refers to its own property, even on another object.
%
% <@Group> Internal helpers
    arguments (Input)
        obj
        s_prop (1,1) string   % Name of the equilibrium property of the parent.
    end
    arguments (Output)
        val   % Value of that property, or zeros(0,1) without a parent.
    end
    if isempty(obj.a_Component)
        val = zeros(0,1);
    else
        val = obj.a_Component.(s_prop);
    end
end
