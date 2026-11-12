function mustBePlotFcn(PlotFcn, s_analysis, sv_key)
% Validate the PlotFcn option of an analysis method of the network (tools.check_plotfcn).
%
% PlotFcn is "none", display keys of the analysis (sv_key) or a function handle; an
% analysis without displays (sv_key empty) accepts "none" only.
    arguments (Input)
        PlotFcn                                 % Value to check.
        s_analysis (1,1) string                 % Name of the analysis method, for the message.
        sv_key     (1,:) string = strings(1,0)  % Display keys of the analysis.
    end
    tools.check_plotfcn(PlotFcn, s_analysis, sv_key);
end
