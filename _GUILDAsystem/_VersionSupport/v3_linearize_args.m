function [c_nv, rv_nonUnit] = v3_linearize_args(c_nv, rv_nonUnit)
% Take the retired NonUnit option out of the options of net.linearize.
%
% v3 compatibility hook of odeLinearizer.get_options: "NonUnit", n warns once
% (GUILDA:Deprecated:LinearizeNonUnit) and is removed from the options. The buses are
% detected automatically, so a listed bus without states changes nothing. rv_nonUnit is
% kept in the options of the result only to report the listed buses that remain errors
% (v3_nonunit_range, v3_nonunit_dynamic). Other arguments are returned unchanged.
%
% Inputs:
%
% - `c_nv` — Name-Value options of the call.
% - `rv_nonUnit` — Value stored in net.solver_LIN.NonUnit, used when the call gives none.
%
% See also odeLinearizer, Deprecated
    arguments (Output)
        c_nv        % Name-Value options without NonUnit.
        rv_nonUnit  % Listed bus indices, as a row.
    end
    if mod(numel(c_nv), 2) ~= 0
        return                          % not Name-Value pairs: resolve_options reports it
    end
    lv_old = false(size(c_nv));
    for k = 1:2:numel(c_nv)
        x = c_nv{k};
        if ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmpi(x, "NonUnit")
            Deprecated("LinearizeNonUnit");
            rv_nonUnit = check_value(c_nv{k+1});
            lv_old(k:k+1) = true;
        end
    end
    c_nv = c_nv(~lv_old);
end


function val = check_value(val)
    arguments
        val (1,:) double {mustBeInteger, mustBePositive}
    end
end
