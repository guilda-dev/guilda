function c_nv = v3_opf_args(c_nv)
% <@Desc>
% v3 compatibility hook of PowerNetwork.optimize_powerflow: rewrites the old option name
% into the v4 one.
%   "methods", m  -> Method=m  (GUILDA:Deprecated:OptimizePowerflowMethods)
% A v4 argument list is returned unchanged.
% <@Role> Compatibility
% <@Summary> Convert the old methods option of optimize_powerflow.
% <@Signatures>
% [
%   "c_nv = v3_opf_args(c_nv)"
% ]
% <@Parameters>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "varargin of optimize_powerflow.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "Name-Value options of the v4 signature."}
% ]
    if mod(numel(c_nv), 2) ~= 0
        return                          % not Name-Value pairs: optimize_powerflow reports it
    end
    for k = 1:2:numel(c_nv)
        x = c_nv{k};
        if ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmpi(x, "methods")
            c_nv{k} = "Method";
            Deprecated("OptimizePowerflowMethods", c_nv{k+1});
        end
    end
end
