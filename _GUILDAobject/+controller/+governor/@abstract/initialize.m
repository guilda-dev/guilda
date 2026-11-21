function initialize(obj, l_equilibrium)
% Bring the governor up to date (LocalController.initialize). With l_equilibrium = true
% and Prate = NaN the handles are rebuilt, so that they use the operation Pmax of the
% generator that get_equilibrium has just read.
    arguments (Input)
        obj
        l_equilibrium (1,1) logical = false  % The component has just set the equilibrium.
    end
    if l_equilibrium && isnan(obj.tab_parameter.dynamics{:, 'Prate'})
        obj.sct_stale.odefcn(end+1,1) = obj.s_tag + ": Prate from the operation Pmax";
    end
    initialize@LocalController(obj, l_equilibrium);
end
