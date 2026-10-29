function c_nv = v3_powerflow_args(c_nv)
% <@Desc>
% v3 compatibility hook of PowerNetwork.calculate_powerflow: rewrites the old arguments
% into v4 Name-Value options.
%   calculate_powerflow(mode, ...)     -> Method=mode  (GUILDA:Deprecated:CalculatePowerflowMode)
%   "export", l, "filename", f         -> Export=fullfile(GUILDA.pwd, f) when l is true
%                                         (GUILDA:Deprecated:CalculatePowerflowExport)
% The old options are recognized only together with the positional mode or "filename";
% "export" alone is the v4 option Export. As in v3, mode "dynamic" exports the JSON
% history by default, and the default file name is <yyMMdd_HHmmss>_PFcalculation.json
% in GUILDA.pwd. A v4 argument list is returned unchanged.
% <@Role> Compatibility
% <@Summary> Convert the old mode argument and export options of calculate_powerflow.
% <@Signatures>
% [
%   "c_nv = v3_powerflow_args(c_nv)"
% ]
% <@Parameters>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "varargin of calculate_powerflow.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "c_nv", "Type": "cell row", "Description": "Name-Value options of the v4 signature."}
% ]
    l_mode = mod(numel(c_nv), 2) == 1 && is_text(c_nv{1}) ...
             && any(strcmpi(c_nv{1}, ["algebraic","dynamic"]));
    str_mode = "";
    if l_mode
        str_mode = lower(string(c_nv{1}));
        c_nv     = c_nv(2:end);
        Deprecated("CalculatePowerflowMode", str_mode);
    end

    if mod(numel(c_nv), 2) ~= 0
        return                          % not Name-Value pairs: calculate_powerflow reports it
    end
    sv_name = strings(1, numel(c_nv)/2);
    for k = 1:numel(sv_name)
        if is_text(c_nv{2*k-1})
            sv_name(k) = string(c_nv{2*k-1});
        end
    end
    iv_file = find(strcmpi(sv_name, "filename"));
    if ~l_mode && isempty(iv_file)
        return                          % v4 call
    end

    % old export options: export (default true for "dynamic"), filename
    iv_export = find(strcmp(sv_name, "export"));
    l_export  = str_mode == "dynamic";
    if ~isempty(iv_export)
        l_export = logical(c_nv{2*iv_export(end)});
    end
    str_file = string(datetime("now","Format","uuMMdd_HHmmss")) + "_PFcalculation.json";
    if ~isempty(iv_file)
        str_file = string(c_nv{2*iv_file(end)});
    end
    if ~isempty(iv_export) || ~isempty(iv_file)
        Deprecated("CalculatePowerflowExport");
    end

    iv_drop = [iv_export, iv_file];
    lv_keep = true(1, numel(c_nv));
    lv_keep([2*iv_drop-1, 2*iv_drop]) = false;
    c_nv = c_nv(lv_keep);
    if l_mode
        c_nv = [{"Method", str_mode}, c_nv];
    end
    if l_export
        c_nv = [c_nv, {"Export", fullfile(GUILDA.pwd, str_file)}];
    end
end


function l = is_text(x)
    l = (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x));
end
