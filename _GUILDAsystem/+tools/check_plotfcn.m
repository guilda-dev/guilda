function check_plotfcn(PlotFcn, s_analysis)
% Check the PlotFcn option of an analysis (live display during the analysis).
%
% PlotFcn is "none", a string array of display keys, or a function handle. The live display
% is under development: only "none" is available, and any other value stops with
% GUILDA:check_plotfcn:InDevelopment. A value of another type stops with
% GUILDA:check_plotfcn:InvalidValue. The figure after the analysis is drawn by the Plot
% method of the result.
%
% <@Examples>
% ```matlab
% tools.check_plotfcn("none", "calculate_powerflow");   % passes
% ```
%
% See also tools.resolve_options
    arguments (Input)
        PlotFcn                  % "none", display keys (string array) or a function handle.
        s_analysis (1,1) string  % Name of the analysis method, for the message.
    end
    if (isstring(PlotFcn) || ischar(PlotFcn)) && all(string(PlotFcn) == "none")
        return
    end
    if ~(isstring(PlotFcn) || ischar(PlotFcn) || iscellstr(PlotFcn) || isa(PlotFcn, "function_handle"))
        error(msg("GUILDA:check_plotfcn:InvalidValue", s_analysis))
    end
    error(msg("GUILDA:check_plotfcn:InDevelopment", s_analysis))
end
