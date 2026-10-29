function c_out = legacy_output(c_new, n_out, iv_old, f_legacy, str_key)
% <@Desc>
% Chooses between the v4 outputs [result, flag, output] and the outputs of the old
% (v3) signature of an analysis method, from the number of outputs requested.
% When n_out is one of iv_old, the old outputs f_legacy(c_new{:}) are returned and
% the deprecation warning GUILDA:Deprecated:<str_key> is issued (once per session);
% otherwise c_new is returned unchanged.
% Use it as the one-line compatibility hook at the end of a method declared with
% varargout, after the line that sets the v4 outputs:
%     varargout = {result, flag, output};
%     varargout = legacy_output(varargout, nargout, 4:6, @v3_optimize_powerflow, "OptimizePowerflowTuple"); % COMPAT(vN)
% Only output counts that the v4 signature cannot have (more than numel(c_new))
% can select the old form unambiguously.
% <@Role> Compatibility
% <@Summary> Return the old output tuple when nargout matches the old signature.
% <@Signatures>
% [
%   "c_out = legacy_output(c_new, n_out, iv_old, f_legacy)",
%   "c_out = legacy_output(c_new, n_out, iv_old, f_legacy, str_key)"
% ]
% <@Parameters>
% [
%   {"Name": "c_new", "Type": "cell row", "Description": "v4 outputs {result, flag, output}.", "Required": true, "Default": "-"},
%   {"Name": "n_out", "Type": "double scalar", "Description": "nargout of the calling method.", "Required": true, "Default": "-"},
%   {"Name": "iv_old", "Type": "double vector", "Description": "Output counts that select the old signature.", "Required": true, "Default": "-"},
%   {"Name": "f_legacy", "Type": "function handle", "Description": "Converter in _VersionSupport/: f_legacy(c_new{:}) returns the old outputs as a cell row.", "Required": true, "Default": "-"},
%   {"Name": "str_key", "Type": "string scalar", "Description": "Key of the deprecation warning in Deprecated.xml; \"\" for no warning.", "Required": false, "Default": "\"\""}
% ]
% <@Returns>
% [
%   {"Name": "c_out", "Type": "cell row", "Description": "Outputs to assign to varargout."}
% ]
    arguments
        c_new    (1,:) cell
        n_out    (1,1) double
        iv_old         double
        f_legacy (1,1) function_handle
        str_key  (1,1) string = ""
    end
    if ~ismember(n_out, iv_old)
        c_out = c_new;
        return
    end
    if str_key ~= ""
        Deprecated(str_key);
    end
    c_out = f_legacy(c_new{:});
end
