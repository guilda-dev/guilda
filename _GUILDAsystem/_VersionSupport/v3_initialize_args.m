function c_nv = v3_initialize_args(c_nv)
% <@Desc>
% v3 compatibility hook of PowerNetwork.initialize: rewrites the old option name and
% values into the v4 ones.
%   "methods", m                    -> Method=m  (GUILDA:Deprecated:InitializeMethods)
%   "powerflow calculation"         -> "powerflow"    (GUILDA:Deprecated:InitializeMethodValue)
%   "optimal powerflow"             -> "OPF"
%   "calculate from Xequilibrium"   -> "equilibrium"
% The old values are accepted under both names. The old output order [flag, tab, output]
% cannot be detected and is not converted. A v4 argument list is returned unchanged.
% <@Role> Compatibility
% <@Summary> Convert the old methods option of initialize.
% <@Signatures>
% [
%   "c_nv = v3_initialize_args(c_nv)"
% ]
% <@Parameters>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "varargin of initialize.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "Name-Value options of the v4 signature."}
% ]
    sv_old = ["powerflow calculation","optimal powerflow","calculate from Xequilibrium"];
    sv_new = ["powerflow","OPF","equilibrium"];
    if mod(numel(c_nv), 2) ~= 0
        return                          % not Name-Value pairs: initialize reports it
    end
    for k = 1:2:numel(c_nv)
        if ~is_text(c_nv{k}) || ~any(strcmpi(c_nv{k}, ["methods","Method"]))
            continue
        end
        l_oldName = strcmpi(c_nv{k}, "methods");
        if l_oldName
            c_nv{k} = "Method";
        end
        v = c_nv{k+1};
        if is_text(v) && any(strcmpi(v, sv_old))
            c_nv{k+1} = sv_new(strcmpi(v, sv_old));
            Deprecated("InitializeMethodValue", v, c_nv{k+1});
        end
        if l_oldName
            Deprecated("InitializeMethods", c_nv{k+1});
        end
    end
end


function l = is_text(x)
    l = (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x));
end
