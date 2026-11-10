function [c_nv, rv_nonUnit] = v3_linearize_args(c_nv, rv_nonUnit)
% Take the retired NonUnit option out of the options of net.linearize and rename Algorithm.
%
% v3 compatibility hook of SolverLIN.get_options (net.linearize and net.get_sys):
%
% - "NonUnit", n warns once (GUILDA:Deprecated:LinearizeNonUnit) and is removed from the
%   options. The buses are detected automatically, so a listed bus without states changes
%   nothing. rv_nonUnit is kept in the options of the result only to report the listed
%   buses that remain errors (v3_nonunit_range, v3_nonunit_dynamic).
% - "Algorithm", a (the v3 name) becomes "Method", a and warns once
%   (GUILDA:Deprecated:LinearizeAlgorithm).
%
% Other arguments are returned unchanged.
%
% See also SolverLIN, Deprecated
    arguments (Input)
        c_nv        % Name-Value options of the call.
        rv_nonUnit  % Value stored in net.solver_LIN.NonUnit, used when the call gives none.
    end
    arguments (Output)
        c_nv        % Name-Value options without NonUnit, with Method for Algorithm.
        rv_nonUnit  % Listed bus indices, as a row.
    end
    if mod(numel(c_nv), 2) ~= 0
        return                          % not Name-Value pairs: resolve_options reports it
    end
    lv_old = false(size(c_nv));
    for k = 1:2:numel(c_nv)
        x = c_nv{k};
        l_text = (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x));
        if l_text && strcmpi(x, "NonUnit")
            Deprecated("LinearizeNonUnit");
            rv_nonUnit = check_value(c_nv{k+1});
            lv_old(k:k+1) = true;
        elseif l_text && strcmpi(x, "Algorithm")
            Deprecated("LinearizeAlgorithm", string(c_nv{k+1}));
            c_nv{k} = "Method";
        end
    end
    c_nv = c_nv(~lv_old);
end


function val = check_value(val)
    arguments (Input)
        val (1,:) double {mustBeInteger, mustBePositive}
    end
end
