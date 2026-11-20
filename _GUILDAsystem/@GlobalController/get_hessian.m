function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the global controller at a point.
%
% The energy-function form of Component.get_hessian for a global controller. No global
% controller supports it yet: this base method stops with
% GUILDA:GlobalController:HessianNotSupported, which names the class, and a class
% supports the form by overriding get_hessian.
%
% See also Component.get_hessian
%
% <@Group> Queries and checks
    arguments (Input)
        obj
        x (:,1) double = obj.rv_Xequilibrium  % States (default: the equilibrium).
        V (:,1) double = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], obj.controlledUnits{1}.a_Bus.a_PowerNetwork.a_Bus)  % [pu] Voltages of all buses [Vre1; Vim1; ...] (default: the equilibrium).
        u (:,1) double = obj.rv_Uequilibrium  % Inputs (the observed outputs or states of the controlled units).
    end
    arguments (Output)
        sct_hessian struct  % Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName.
    end
    error(msg("GUILDA:GlobalController:HessianNotSupported", class(obj), "the class does not override get_hessian"))
end
