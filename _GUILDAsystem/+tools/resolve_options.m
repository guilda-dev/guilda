function [s_options, sv_given] = resolve_options(solver, s_map, nv)
% Merge the stored solver defaults with the call-time overrides into the effective settings.
%
% Merges the stored defaults of a solver object (net.solver_*) with the Name-Value
% overrides of one call and returns the effective settings. The solver object is only
% read: the overrides apply to this call and never change the stored defaults.
% s_map lists the Name-Value names an analysis accepts (UpperCamelCase common names
% such as Method, Tolerance, MaxIteration, Solver, TimeLimit, Verbose) and the solver
% field each one sets. A name that is not in s_map stops with the error
% GUILDA:resolve_options:UnknownName, which lists the accepted names.
% s_options has one field per solver field named in s_map (the top-level property for
% a nested path such as "dynamic.t_span"); the stored value when the name was not
% given, the override otherwise. Name matching is case-insensitive.
%
% <@Examples>
% ```matlab
% s_map = struct("MaxIteration", "MaxIterations", ...
%                "Verbose",      {{"Display", @(l) replace(string(l), ["true","false"], ["iter","none"])}});
% opt = tools.resolve_options(net.solver_PF, s_map, {"MaxIteration", 50});
% opt.MaxIterations   % 50; net.solver_PF.MaxIterations is unchanged
% ```
    arguments
        solver % Holder of the stored defaults, e.g. net.solver_PF. Only read.
        s_map (1,1) struct % One field per accepted Name-Value name. The value is the solver field it sets: a string ("MaxIterations"), a string array to set several fields, a dotted path into a struct property ("dynamic.t_span"), or a cell {field, fcn} where fcn converts the given value (e.g. Verbose=true -> Display="iter").
        nv          = struct() % Overrides of this call: the struct of an arguments block (opt.Name with no default, so only given names are fields) or a cell {Name1, Value1, ...}.
    end
    arguments (Output)
        s_options % Effective settings, keyed by solver field name.
        sv_given % Accepted names given in this call, in s_map spelling.
    end

    str_solver = string(class(solver));
    sv_names   = string(fieldnames(s_map)).';

    % Name-Value pairs of this call
    if isstruct(nv)
        sv_in = string(fieldnames(nv)).';
        c_in  = struct2cell(nv).';
    elseif iscell(nv)
        if mod(numel(nv), 2) ~= 0
            error('GUILDA:resolve_options:InvalidPairs', '%s', ...
                  msg('GUILDA:resolve_options:InvalidPairs', char(str_solver)));
        end
        sv_in = string(nv(1:2:end));
        c_in  = nv(2:2:end);
    else
        error('GUILDA:resolve_options:InvalidPairs', '%s', ...
              msg('GUILDA:resolve_options:InvalidPairs', char(str_solver)));
    end

    % Stored defaults of every field the map refers to
    s_options = struct();
    c_target  = cell(size(sv_names));
    for i = 1:numel(sv_names)
        [sv_path, f_convert] = map_entry(s_map.(sv_names(i)));
        c_target{i} = {sv_path, f_convert};
        for path = sv_path
            sv_part = split(path, ".").';
            if ~has_field(solver, sv_part(1))
                error('GUILDA:resolve_options:UnknownField', '%s', ...
                      msg('GUILDA:resolve_options:UnknownField', char(sv_names(i)), char(path), char(str_solver)));
            end
            if ~isfield(s_options, sv_part(1))
                s_options.(sv_part(1)) = solver.(sv_part(1));
            end
            if numel(sv_part) > 1 && ~has_path(s_options.(sv_part(1)), sv_part(2:end))
                error('GUILDA:resolve_options:UnknownField', '%s', ...
                      msg('GUILDA:resolve_options:UnknownField', char(sv_names(i)), char(path), char(str_solver)));
            end
        end
    end

    % Overrides (a repeated name: the last one wins)
    sv_given = strings(1,0);
    for k = 1:numel(sv_in)
        idx = find(strcmpi(sv_in(k), sv_names), 1);
        if isempty(idx)
            error('GUILDA:resolve_options:UnknownName', '%s', ...
                  msg('GUILDA:resolve_options:UnknownName', char(sv_in(k)), char(str_solver), ...
                      char(join(sv_names, ", "))));
        end
        [sv_path, f_convert] = c_target{idx}{:};
        val = c_in{k};
        if ~isempty(f_convert)
            val = f_convert(val);
        end
        for path = sv_path
            sv_part   = cellstr(split(path, ".").');
            s_options = setfield(s_options, sv_part{:}, val);
        end
        sv_given = [sv_given(sv_given ~= sv_names(idx)), sv_names(idx)];
    end
end


function [sv_path, f_convert] = map_entry(entry)
    f_convert = [];
    if iscell(entry)
        if numel(entry) >= 2
            f_convert = entry{2};
        end
        entry = entry{1};
    end
    sv_path = reshape(string(entry), 1, []);
end

function l = has_field(solver, str_name)
    if isstruct(solver)
        l = isfield(solver, str_name);
    else
        l = isprop(solver, str_name);
    end
end

function l = has_path(s, sv_part)
    l = true;
    for p = sv_part
        if ~isstruct(s) || ~isfield(s, p)
            l = false;
            return
        end
        s = s.(p);
    end
end
