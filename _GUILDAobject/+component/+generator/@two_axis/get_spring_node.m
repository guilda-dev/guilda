function [cv_E, rv_P, rv_Iq, cv_I] = get_spring_node(rm_x, rm_V, rm_I, rm_u, rr_param)
% Return the internal voltage node and the sizes of its arrows for the spring-mass drawings.
%
% The own node of the generator is the transient voltage (Eq, Ed) behind the transient reactances.
% It is joined to the bus by the machine reactance in the spring-mass drawings
% (`GraphSpring2D`, `GraphSpring3D`).
%
% The dq frame is the one of `fcn_I`: Vq + jVd = e^{jδ}·conj(V), so a dq pair maps to the
% network frame as X = e^{jδ}(Xq − jXd). The current injected into the bus is
% I = e^{jδ}(Iq − jId) with Id and Iq of `fcn_I`, and the node is
% E = e^{jδ}(Eq − jEd) with the states Eq and Ed.
% The arrows are sized at the node: P = real(E.*conj(I)), Iq = imag(E.*conj(I))./abs(E).
%
% All arguments are vectorized over time: column k is time k (n_t columns). `rm_I` is
% not used: the current is computed from the states, the voltage and the inputs.
%
% See also Component.get_spring_node, fcn_I
    arguments (Input)
        rm_x     double  % States (n_x × n_t) in the order of `sv_x`.
        rm_V     double  % [pu] Bus voltage (2 × n_t) as `[real; imag]`.
        rm_I     double  % [pu] Current attributed to this component (2 × n_t); not used.
        rm_u     double  % Inputs (n_u × n_t) in the order of `sv_u`.
        rr_param double  % Dynamic parameters in the order of `sv_para`.
    end
    arguments (Output)
        cv_E   % [pu] Complex internal voltage phasor (1 × n_t).
        rv_P   % [pu] Active power at the internal node (1 × n_t).
        rv_Iq  % [pu] Reactive-current magnitude Q/|E| (1 × n_t).
        cv_I   % [pu] Complex current injected into the bus (1 × n_t), equal to `fcn_I`.
    end
    rv_delta = rm_x(1,:);
    cv_rot   = exp(1j*rv_delta);
    cv_Vdq   = cv_rot .* conj([1,1j]*rm_V);
    rv_Vd    = imag(cv_Vdq);
    rv_Vq    = real(cv_Vdq);

    Xdp   = rr_param(4);
    Xqp   = rr_param(6);
    rv_Eq = rm_x(3,:);
    rv_Ed = rm_x(4,:);
    rv_Idaxis = (rv_Eq - rv_Vq) / Xdp;
    rv_Iqaxis = (rv_Vd - rv_Ed) / Xqp;

    cv_I  = cv_rot .* (rv_Iqaxis - 1j*rv_Idaxis);
    cv_E  = cv_rot .* (rv_Eq - 1j*rv_Ed);
    cv_S  = cv_E .* conj(cv_I);
    rv_P  = real(cv_S);
    rv_Iq = imag(cv_S) ./ abs(cv_E);
end
