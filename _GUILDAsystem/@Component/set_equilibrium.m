function set_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Compute and store the state and input equilibria from the bus voltage and current.
%
% Called by Bus.set_equilibrium and initialize. Clears the stale tag equilibrium. The
% local controllers compute their equilibria too and are then initialized with
% l_equilibrium = true (LocalController.initialize), which clears theirs. Stale handles
% are rebuilt first: a controller may design from them (local_LQR).
%
% <@Group> Called by analyses
    arguments (Input)
        obj 
        c_V   % [pu] Bus voltage phasor.
        c_I   % [pu] Current injected by the component.
        r_P = real( c_V*conj(c_I) );   % [pu] Active power injected by the component.
        r_Q = imag( c_V*conj(c_I) );   % [pu] Reactive power injected by the component.
    end
    if ~isempty(obj.sct_stale.odefcn) || ~isequal(obj.r_odefcnHz, obj.get_Hz())
        obj.build_odefcn();
    end
    [cv_Xst,cv_Ust] = obj.get_equilibrium(c_V,c_I,r_P,r_Q);
    
    % c_V is the voltage of the bus (its owner); c_Vequilibrium reads it from there.
    obj.c_Iequilibrium  = c_I;
    obj.rv_Xequilibrium = cv_Xst;
    obj.rv_Uequilibrium = cv_Ust;

    obj.sct_stale.equilibrium = strings(0,1);

    % the controllers clear their own stale tag equilibrium (initialize(true))
    for k = 1:numel(obj.a_LocalController)
        obj.a_LocalController{k}.get_equilibrium(c_V, cv_Ust);
        obj.a_LocalController{k}.initialize(true);
    end
end
