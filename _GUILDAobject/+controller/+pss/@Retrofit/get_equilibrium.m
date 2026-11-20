function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x) %#ok<INUSD>
% Return the controller at the point: hat_x = x and the observed signals = x, the state of the generator there.
% Only the arguments are read: nothing is stored and K is not designed here (initialize
% designs it after the equilibrium is set). At another point than the equilibrium of
% net.initialize (a step of the continuation power flow, a point of the
% stability-constrained OPF), K, A_d and u* stay as designed at that equilibrium, so the
% compensator moves there: E dhat_x/dt = f(x, V, u*) is not 0 when u differs from u*.
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the generator at the point (unused).
        u  % Input of the generator at the point (unused).
        x  % State of the generator at the point, in the order of its sv_x.
    end
    arguments (Output)
        rv_Xequilibrium  % State hat_x at the point: the state of the generator.
        rv_Uequilibrium  % Observed signals at the point: the state of the generator.
    end
    rv_Xequilibrium = reshape(x, [], 1);
    rv_Uequilibrium = reshape(x, [], 1);
end
