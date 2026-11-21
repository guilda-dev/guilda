function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium_at(obj, V, u, x)
% Call get_equilibrium(V, u, x); a subclass with get_equilibrium(obj, V, u) is called with three arguments.
%
% Component.set_equilibrium, the continuation power flow (operating points of the steps)
% and the stability-constrained OPF (stability_point) call the controllers through this,
% so a user-defined controller without the fourth argument keeps working. Only the error
% MATLAB:TooManyInputs of this call itself selects the three-argument form; an error
% inside get_equilibrium is raised as it is.
%
% <@Group> Internal helpers
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the component at the point.
        u  % Input of the component at the point, in the order of its sv_u.
        x  % State of the observed component at the point, in the order of its sv_x.
    end
    arguments (Output)
        rv_Xequilibrium  % State of the controller at the point, in the order of sv_x.
        rv_Uequilibrium  % Input of the controller at the point, in the order of sv_u.
    end
    try
        [rv_Xequilibrium, rv_Uequilibrium] = obj.get_equilibrium(V, u, x);
    catch ME
        if ME.identifier ~= "MATLAB:TooManyInputs" || ~endsWith(string(ME.stack(1).name), "get_equilibrium_at")
            rethrow(ME)
        end
        [rv_Xequilibrium, rv_Uequilibrium] = obj.get_equilibrium(V, u);
    end
end
