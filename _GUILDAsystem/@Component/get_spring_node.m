function [cv_E, rv_P, rv_Iq, cv_I] = get_spring_node(rm_x, rm_V, rm_I, rm_u, rr_param)
% Return the own node of the component and the sizes of its arrows for the spring-mass drawings.
%
% The spring-mass drawings of a network (`GraphSpring2D`, `GraphSpring3D`) draw the voltage
% phasors as nodes and the lines and machine reactances as springs. This method tells the
% drawer whether the component has a node of its own (such as the internal voltage of a
% synchronous generator, joined to its bus by the machine reactance) and gives the active
% power and reactive current that size the arrows of the component.
%
% All arguments are vectorized over time: column k is time k (n_t columns).
%
% The base class has no own node: it returns `cv_E = []` and evaluates the power at the bus
% voltage V with the current `rm_I` attributed to this component by the caller:
% P = real(V.*conj(I)), Iq = imag(V.*conj(I))./abs(V) and `cv_I = I`. A model with its own
% node overrides this static method, computes its node phasor E and its injected current
% from `rm_x`, `rm_V`, `rm_u` and `rr_param` (ignoring `rm_I`) and evaluates the power at E.
%
% See also component.generator.one_axis.get_spring_node, PowerNetwork.plot_spring_model, ResultODE.plot_spring_model
    arguments (Input)
        rm_x     double  % States (n_x × n_t) in the order of `sv_x`.
        rm_V     double  % [pu] Bus voltage (2 × n_t) as `[real; imag]`.
        rm_I     double  % [pu] Current attributed to this component (2 × n_t) as `[real; imag]`.
        rm_u     double  % Inputs (n_u × n_t) in the order of `sv_u`.
        rr_param double  % Dynamic parameters in the order of `sv_para`.
    end
    arguments (Output)
        cv_E   % [pu] Complex phasor of the own node (1 × n_t); [] when the component has no own node.
        rv_P   % [pu] Active power at the node (1 × n_t).
        rv_Iq  % [pu] Reactive-current magnitude Q/|node voltage| (1 × n_t).
        cv_I   % [pu] Complex current injected into the bus (1 × n_t).
    end
    cv_V  = [1,1j]*rm_V;
    cv_I  = [1,1j]*rm_I;
    cv_S  = cv_V .* conj(cv_I);
    cv_E  = [];
    rv_P  = real(cv_S);
    rv_Iq = imag(cv_S) ./ abs(cv_V);
end
