function require_toolbox(s_toolbox, s_feature)
% Stop with an error when a MathWorks toolbox needed by a feature is not available.
%
% Checks that the toolbox is installed (ver) and licensed (license test). Call it at the
% start of a feature that needs an optional toolbox; it returns nothing when the toolbox
% is available and otherwise stops with GUILDA:require_toolbox:Unavailable, naming the
% toolbox and the feature.
%
% - "optim": Optimization Toolbox
% - "control": Control System Toolbox
% - "symbolic": Symbolic Math Toolbox
%
% <@Examples>
% ```matlab
% tools.require_toolbox("optim", "OPF");
% ```
    arguments (Input)
        s_toolbox (1,1) string {mustBeMember(s_toolbox,["optim","control","symbolic"])}  % Short name of the toolbox.
        s_feature (1,1) string                                                         % Feature that needs it (shown in the message).
    end
    switch s_toolbox
        case "optim";    s_license = "Optimization_Toolbox"; s_name = "Optimization Toolbox";
        case "control";  s_license = "Control_Toolbox";      s_name = "Control System Toolbox";
        case "symbolic"; s_license = "Symbolic_Toolbox";     s_name = "Symbolic Math Toolbox";
    end
    if ~(license('test', s_license) && ~isempty(ver(s_toolbox)))
        error(msg("GUILDA:require_toolbox:Unavailable", s_feature, s_name))
    end
end
