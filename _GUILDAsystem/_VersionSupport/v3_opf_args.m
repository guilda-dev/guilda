function c_nv = v3_opf_args(c_nv, str_key)
% <@Desc>
% v3 compatibility hook of PowerNetwork.optimize_powerflow and build_opf_problem: rewrites
% the old option name into the v4 one.
%   "methods", m  -> Method=m  (GUILDA:Deprecated:<str_key>)
% A v4 argument list is returned unchanged.
% <@Role> Compatibility
% <@Summary> Convert the old methods option of optimize_powerflow.
% <@Signatures>
% [
%   "c_nv = v3_opf_args(c_nv)",
%   "c_nv = v3_opf_args(c_nv, str_key)"
% ]
% <@Parameters>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "varargin of optimize_powerflow or build_opf_problem.", "Required": true, "Default": "-"},
%   {"Name": "str_key", "Type": "string", "Description": "Key of the deprecation message.", "Required": false, "Default": "\"OptimizePowerflowMethods\""}
% ]
% <@Returns>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "Name-Value options of the v4 signature."}
% ]
    arguments
        c_nv    cell
        str_key (1,1) string = "OptimizePowerflowMethods"
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
