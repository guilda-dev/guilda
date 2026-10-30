function c_out = legacy_output(c_new, n_out, iv_old, f_legacy, str_key)
% Return the old output tuple when nargout matches the old signature.
%
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
%
% See also Deprecated
    arguments
        c_new    (1,:) cell   % v4 outputs {result, flag, output}.
        n_out    (1,1) double   % nargout of the calling method.
        iv_old         double   % Output counts that select the old signature.
        f_legacy (1,1) function_handle   % Converter in _VersionSupport/: f_legacy(c_new{:}) returns the old outputs as a cell row.
        str_key  (1,1) string = ""   % Key of the deprecation warning in Deprecated.xml; "" for no warning.
    end
    arguments (Output)
        c_out   % Outputs to assign to varargout.
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
