function iv_section = section_list(obj, opt)
% Sections chosen by the options Index and Time of a method of ResultLIN: Time (the section
% whose rv_t is nearest) overrides Index; Index "all" gives every section
    arguments (Input)
        obj    ResultLIN  % The result.
        opt    struct     % Options of the method with the field Index and, when given, Time.
    end
    arguments (Output)
        iv_section (1,:) double  % Sections, in order.
    end
    n_t = numel(obj.rv_t);
    if isfield(opt, "Time")
        [~, iv_section] = min(abs(obj.rv_t - opt.Time));
    elseif isstring(opt.Index) || ischar(opt.Index)
        iv_section = 1:n_t;
    else
        iv_section = double(opt.Index);
        if iv_section > n_t
            error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
        end
    end
end
