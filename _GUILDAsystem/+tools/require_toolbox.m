function require_toolbox(s_toolbox, s_feature)
% Stop with an error when a MathWorks toolbox needed by a feature is not available.
%
% Checks that the toolbox is installed (ver) and licensed (license test). Call it at the
% start of a feature that needs an optional toolbox; it returns nothing when the toolbox
% is available and otherwise stops with GUILDA:require_toolbox:Unavailable, naming the
% toolbox and the feature. The toolbox names and license features are read from
% ./@GUILDA/config/ListToolbox.json.
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
    sct = jsondecode(fileread(fullfile(GUILDA.pwd, "@GUILDA", "config", "ListToolbox.json")));
    s_license = sct.(s_toolbox).License;
    s_name    = sct.(s_toolbox).Name;
    if ~(license('test', s_license) && ~isempty(ver(s_toolbox)))
        error(msg("GUILDA:require_toolbox:Unavailable", s_feature, s_name))
    end
end
