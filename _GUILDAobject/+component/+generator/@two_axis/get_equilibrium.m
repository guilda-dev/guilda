function [rv_Xequilibrium,rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the equilibrium state and the steady inputs from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The rotor angle comes
% from the terminal voltage and the injected power; the speed deviation is 0.
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

    para = obj.para_dynamics.tab_parameter{:,obj.sv_para};
            
    Xd   = para(3);
    Xq   = para(5);
    Xdp  = para(4);
    Xqp  = para(6);
    
    dst = Varg + atan(r_P/(r_Q+Vabs^2/Xq));
    wst = 0;
    
    Idq = exp(1j*dst) * conj(c_I);
    Iq  = real(Idq);
    Id  = imag(Idq);
    Vfd = Xd/Vabs * ( (r_Q+Vabs^2/Xq)*(r_Q+Vabs^2/Xd) + r_P^2 ) / sqrt( (r_Q+Vabs^2/Xq)^2 + r_P^2 );
    Est = [ -(Xd-Xdp)*Id + Vfd; ...
             (Xq-Xqp)*Iq      ];
    
    rv_Xequilibrium = [dst; wst; Est];
    rv_Uequilibrium = [r_P;Vfd];
end