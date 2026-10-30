function set_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Compute and store the state and input equilibria from the bus voltage and current.
%
% Called by Bus.set_equilibrium. The local controllers compute their equilibria too.
    arguments
        obj 
        c_V   % [pu] Bus voltage phasor.
        c_I   % [pu] Current injected by the component.
        r_P = real( c_V*conj(c_I) );   % [pu] Active power injected by the component.
        r_Q = imag( c_V*conj(c_I) );   % [pu] Reactive power injected by the component.
    end
    [cv_Xst,cv_Ust] = obj.get_equilibrium(c_V,c_I,r_P,r_Q);
    
    % c_V is the voltage of the bus (its owner); c_Vequilibrium reads it from there.
    obj.c_Iequilibrium  = c_I;
    obj.rv_Xequilibrium = cv_Xst;
    obj.rv_Uequilibrium = cv_Ust;

    if ~isempty(obj.a_LocalController)
        cellfun(@(con) con.get_equilibrium(c_V, cv_Ust), obj.a_LocalController);        
    end
end