function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the equilibrium state and the steady inputs from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The current of the internal
% classical model is the bus current rotated back by `alpha`, `exp(-1j*alpha)*c_I`; the
% internal angle and `Vref` follow from it and the terminal voltage as in the classical
% generator. `Pref` is the virtual power of the swing equation at the equilibrium,
% P~ = Re(c_V*conj(exp(-1j*alpha)*c_I)) = cos(alpha)*r_P - sin(alpha)*r_Q, and the
% frequency deviation is 0. The power flow fixes the bus power r_P, r_Q; P~ equals r_P
% only with `alpha = 0`.
%
% See also fcn_dx, Component.rv_Xequilibrium, component.generator.classical.get_equilibrium
arguments (Input)
    obj
    c_V                        % [pu] Complex bus voltage of the power-flow solution.
    c_I                        % [pu] Complex current injected into the bus.
    r_P = real(c_V*conj(c_I))  % [pu] Active power injected into the bus.
    r_Q = imag(c_V*conj(c_I))  % [pu] Reactive power injected into the bus.
end
arguments (Output)
    rv_Xequilibrium  % Equilibrium state in the order of `sv_x`.
    rv_Uequilibrium  % Steady input in the order of `sv_u`.
end

    Vabs = abs(c_V);
    Varg = angle(c_V);

    Xd    = obj.tab_parameter.dynamics{:,'Xd'};
    Xq    = obj.tab_parameter.dynamics{:,'Xq'};
    alpha = obj.tab_parameter.dynamics{:,'alpha'};

    c_Iint = exp(-1j*alpha)*c_I;
    c_Sint = c_V*conj(c_Iint);

    dst = Varg + atan2(real(c_Sint), imag(c_Sint)+Vabs^2/Xq);

    Id   = real(  1j*c_Iint*exp(-1j*dst) );
    Vq   = imag(  1j*c_V*exp(-1j*dst) );
    Vref = Id*Xd+Vq;

    rv_Xequilibrium = [dst; 0];
    rv_Uequilibrium = [cos(alpha)*r_P - sin(alpha)*r_Q; Vref];
end
