function [cv_E, rv_P, rv_Iq, cv_I] = get_spring_node(rm_x, rm_V, rm_I, rm_u, rr_param)
% Return the internal voltage node and the sizes of its arrows for the spring-mass drawings.
%
% The own node of the inverter is the internal voltage `Vref` (the input u) at the
% internal angle, joined to the bus by the virtual reactance in the spring-mass drawings
% (`GraphSpring2D`, `GraphSpring3D`), as for `component.generator.classical`.
%
% The dq frame is the one of `fcn_I`: Vq + jVd = e^{jδ}·conj(V). The classical current
% is I0 = e^{jδ}(Iq − jId) and the node is E = e^{jδ}·Vref (not rotated). The arrows are
% sized at the node with I0, the current of the virtual reactance and of the swing
% equation: P = real(E.*conj(I0)), Iq = imag(E.*conj(I0))./abs(E) (P is the virtual power
% P~ of the swing equation when Xd = Xq). The current injected into the bus is
% I = e^{jα}·I0; with alpha ≠ 0 the reactance between E and the bus does not carry I, so
% the drawing is only indicative.
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
        rv_P   % [pu] Active power of the classical current at the internal node (1 × n_t).
        rv_Iq  % [pu] Reactive-current magnitude Q/|E| (1 × n_t).
        cv_I   % [pu] Complex current injected into the bus (1 × n_t), equal to `fcn_I`.
    end
    rv_delta = rm_x(1,:);
    cv_rot   = exp(1j*rv_delta);
    cv_Vdq   = cv_rot .* conj([1,1j]*rm_V);
    rv_Vd    = imag(cv_Vdq);
    rv_Vq    = real(cv_Vdq);

    Xd    = rr_param(3);
    Xq    = rr_param(4);
    alpha = rr_param(5);
    rv_Eq = rm_u(2,:);
    rv_Idaxis = (rv_Eq - rv_Vq) / Xd;
    rv_Iqaxis = rv_Vd / Xq;

    cv_I0 = cv_rot .* (rv_Iqaxis - 1j*rv_Idaxis);
    cv_I  = exp(1j*alpha) * cv_I0;
    cv_E  = cv_rot .* rv_Eq;
    cv_S  = cv_E .* conj(cv_I0);
    rv_P  = real(cv_S);
    rv_Iq = imag(cv_S) ./ abs(cv_E);
end
