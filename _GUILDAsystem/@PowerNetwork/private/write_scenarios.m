function write_scenarios(net, path)
% Write each scenario of net to <path>/scenario/<tag>.json (net.export).
%
% Nothing is written, and no folder made, when net has no scenarios. Inf and NaN are
% written as Infinity and NaN (read back by jsondecode).
    arguments (Input)
        net PowerNetwork    % Network whose scenarios are written.
        path (1,1) string   % Model folder.
    end
    if isempty(net.a_Scenario)
        return
    end
    s_dir = fullfile(path, "scenario");
    mkdir(s_dir);
    for k = 1:numel(net.a_Scenario)
        sc = net.a_Scenario{k};
        s_json = jsonencode(sc.to_json_struct(), PrettyPrint=true, ConvertInfAndNaN=false);
        writelines(s_json, fullfile(s_dir, sc.s_tag + ".json"));
    end
end
