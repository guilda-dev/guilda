function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x) %#ok<INUSD>
% Return the controller at the point: no state, and the observed signals = x, the state of the component there.
% Only the arguments are read: nothing is stored and the gain K is not designed here
% (initialize designs it after the equilibrium is set). At another point than the
% equilibrium of net.initialize (a step of the continuation power flow, a point of the
% stability-constrained OPF), K, x* and u* stay as designed at that equilibrium, so the
% output u* - K (x - x*) there is not the input u of the component at the point.
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the component at the point (unused).
        u  % Input of the component at the point (in the order of its sv_u; unused).
        x  % State of the component at the point, in the order of its sv_x.
    end
    arguments (Output)
        rv_Xequilibrium  % State (none).
        rv_Uequilibrium  % Observed signals at the point: the state of the component.
    end
    rv_Xequilibrium = zeros(0,1);
    rv_Uequilibrium = reshape(x, [], 1);
end
