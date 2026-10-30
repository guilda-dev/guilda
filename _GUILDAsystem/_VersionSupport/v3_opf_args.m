function c_nv = v3_opf_args(c_nv, str_key)
% Convert the old methods option of optimize_powerflow and build_opf_problem.
%
% v3 compatibility hook of PowerNetwork.optimize_powerflow and build_opf_problem: rewrites
% the old option name into the v4 one.
%   "methods", m  -> Method=m  (GUILDA:Deprecated:<str_key>)
% A v4 argument list is returned unchanged.
%
% See also PowerNetwork.optimize_powerflow
    arguments
        c_nv    cell   % varargin of optimize_powerflow or build_opf_problem.
        str_key (1,1) string = "OptimizePowerflowMethods"   % Key of the deprecation message.
    end
    arguments (Output)
        c_nv   % Name-Value options of the v4 signature.
    end
    if mod(numel(c_nv), 2) ~= 0
        return                          % not Name-Value pairs: the caller reports it
    end
    for k = 1:2:numel(c_nv)
        x = c_nv{k};
        if ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmpi(x, "methods")
            c_nv{k} = "Method";
            Deprecated(str_key, c_nv{k+1});
        end
    end
end
