function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q) 
% Calculate the equilibrium state and the steady inputs from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The rotor angle comes
% from the terminal voltage and the injected power.
%
% See also fcn_dx, Component.rv_Xequilibrium
    arguments
        obj 
        c_V % [pu] Complex bus voltage of the power-flow solution.
        c_I % [pu] Complex current injected into the bus.
        r_P = real(c_V*conj(c_I)) % [pu] Active power injected into the bus.
        r_Q = imag(c_V*conj(c_I)) % [pu] Reactive power injected into the bus.
    end
    arguments (Output)
        rv_Xequilibrium % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium % Steady input in the order of `sv_u`.
    end

    Vabs = abs(c_V);
    Varg = angle(c_V);
        
    Xd = obj.tab_parameter.dynamics{:,'Xd'};
    Xq = obj.tab_parameter.dynamics{:,'Xq'};
    
    dst = Varg + atan(r_P/(r_Q+Vabs^2/Xq));    
    
    Id = real(  1j*c_I*exp(-1j*dst) );
    Vq = imag(  1j*c_V*exp(-1j*dst) );
    Vfd = Id*Xd+Vq;
    
    rv_Xequilibrium = dst;
    rv_Uequilibrium = [r_P;Vfd];
end