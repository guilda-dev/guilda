function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the local controller at a point (port "PI").
%
% The same form as Component.get_hessian: with the deviations x of the states and
% v = [theta; V] of the bus of the parent component,
%   dx/dt = -R (Hxx x + Hxv v),   w_dev = Hvx x + Hvv v,
% and a struct with the fields Hxx (n_x x n_x), Hxv (n_x x 2), Hvx (2 x n_x),
% Hvv (2 x 2), R (n_x x n_x), StateName and PortName (theta and V of the bus). A local
% controller injects no current, so its w_dev is zero; its inputs u are constants of the
% point.
%
% This base method stops with GUILDA:LocalController:HessianNotSupported, which names
% the class; a class supports the form by overriding get_hessian. The stateless default
% controllers controller.governor.Static and controller.avr.Static return empty blocks,
% so the default generators support the form.
%
% See also Component.get_hessian
%
% <@Group> Queries and checks
    arguments (Input)
        obj
        x (:,1) double = obj.rv_Xequilibrium  % States (default: the equilibrium).
        V (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]  % [pu] Voltage [Vre; Vim] of the parent.
        u (:,1) double = obj.rv_Uequilibrium  % Inputs (default: the equilibrium).
    end
    arguments (Output)
        sct_hessian struct  % Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName.
    end
    error(msg("GUILDA:LocalController:HessianNotSupported", class(obj), "the class does not override get_hessian"))
end
