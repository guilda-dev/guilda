function varargout = disp_violation(obj, opt)
% Display the violated operating limits of the power flow result.
%
% Shows tab_violation grouped by kind (Bus, Component, Branch): for each violated limit
% its object, the limit, the solution value, the bound and the excess. A kind without a
% violation is left out; without any, one line says so. The power flow never applies the
% limits (see ResultPF). It reads only the stored result. With one output it returns the
% text instead of displaying it.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% res.disp_violation()
% res.disp_violation(Class="Branch")
% ```
%
% See also ResultPF.tab_violation, ResultPF.disp_summary
    arguments (Input)
        obj
        opt.Class (1,:) string {mustBeMember(opt.Class, ["Bus","Component","Branch"])} = ["Bus","Component","Branch"] % Kinds of object shown.
    end
    arguments (Output, Repeating)
        varargout % Text when one output is requested; displayed otherwise.
    end
    tab = obj.tab_violation;
    sv  = strings(0,1);
    for s_class = ["Bus","Component","Branch"]
        if ~ismember(s_class, opt.Class) || width(tab) == 0
            continue
        end
        tab_c = tab(tab.Class == s_class, ["Object","Limit","Value","Bound","Excess"]);
        if height(tab_c) == 0
            continue
        end
        sv(end+1,1) = s_class + " (" + height(tab_c) + ")"; %#ok<AGROW>
        sv(end+1,1) = string(formattedDisplayText(tab_c, "SuppressMarkup", true)); %#ok<AGROW>
    end
    if isempty(sv)
        sv = "No violated operating limits" + " (" + join(opt.Class, ", ") + ").";
    end
    varargout = show_text(join(sv, newline), nargout);
end
