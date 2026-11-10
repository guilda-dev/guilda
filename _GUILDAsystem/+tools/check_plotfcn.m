function PlotFcn = check_plotfcn(PlotFcn, s_analysis, sv_key)
% Check the PlotFcn option of an analysis (live display during the analysis).
%
% PlotFcn is "none", a string array of the display keys of the analysis (sv_key), or a
% function handle; it returns the value as "none", a row of distinct keys or the handle.
%
% - An analysis without displays (sv_key empty) accepts "none" only: any other value stops
%   with GUILDA:check_plotfcn:InDevelopment.
% - A key that is not in sv_key stops with GUILDA:check_plotfcn:UnknownKey (naming the
%   keys of the analysis); "none" together with keys, an empty array or a value of another
%   type stops with GUILDA:check_plotfcn:InvalidValue.
% - The figure after the analysis is drawn by the Plot method of the result.
%
% <@Examples>
% ```matlab
% tools.check_plotfcn("none", "calculate_powerflow", "residual");       % "none"
% tools.check_plotfcn("residual", "calculate_powerflow", "residual");   % "residual"
% ```
%
% See also tools.resolve_options
    arguments (Input)
        PlotFcn                                 % "none", display keys (string array) or a function handle.
        s_analysis (1,1) string                 % Name of the analysis method, for the message.
        sv_key     (1,:) string = strings(1,0)  % Display keys of the analysis; empty when it has none yet.
    end
    arguments (Output)
        PlotFcn  % "none", a row of distinct keys, or the function handle.
    end
    if iscellstr(PlotFcn) || ischar(PlotFcn)
        PlotFcn = string(PlotFcn);
    end
    if isstring(PlotFcn) && isscalar(PlotFcn) && PlotFcn == "none"
        return
    end
    l_text = isstring(PlotFcn) && ~isempty(PlotFcn) && ~any(ismissing(PlotFcn));
    if ~(l_text || isa(PlotFcn, "function_handle") && isscalar(PlotFcn))
        error(msg("GUILDA:check_plotfcn:InvalidValue", s_analysis))
    end
    if isempty(sv_key)
        error(msg("GUILDA:check_plotfcn:InDevelopment", s_analysis))
    end
    if isa(PlotFcn, "function_handle")
        return
    end
    PlotFcn = unique(reshape(PlotFcn, 1, []), "stable");
    if any(PlotFcn == "none")
        error(msg("GUILDA:check_plotfcn:InvalidValue", s_analysis))
    end
    sv_unknown = setdiff(PlotFcn, sv_key, "stable");
    if ~isempty(sv_unknown)
        error(msg("GUILDA:check_plotfcn:UnknownKey", s_analysis, join("""" + sv_unknown + """", ", "), ...
                  join("""" + sv_key + """", ", ")))
    end
end
