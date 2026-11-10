function [sct_options, sv_given] = resolve_options(solver, sct_map, nv)
% Merge the stored solver defaults with the call-time overrides into the effective settings.
%
% Merges the defaults held by a solver object (net.solver_*) or a struct (SolverPF passes
% the values of its GUILDA.setting section) with the Name-Value overrides of one call and
% returns the effective settings. The holder is only read: the overrides apply to this
% call and never change the defaults.
% sct_map lists the Name-Value names an analysis accepts (UpperCamelCase common names
% such as Method, Tolerance, MaxIteration, Solver, TimeLimit, Verbose) and the solver
% field each one sets. A name that is not in sct_map stops with the error
% GUILDA:resolve_options:UnknownName, which lists the accepted names.
% sct_options has one field per solver field named in sct_map (the top-level field for
% a nested path such as "sct_ode.Events"); the stored value when the name was not
% given, the override otherwise. Name matching is case-insensitive.
%
% <@Examples>
% ```matlab
% sct_def = struct("MaxIteration", 500, "Verbose", false);   % defaults, e.g. of GUILDA.config
% sct_map = struct("MaxIteration", "MaxIteration", ...
%                "Verbose",      {{"Verbose", @logical}});
% opt = tools.resolve_options(sct_def, sct_map, {"MaxIteration", 50});
% opt.MaxIteration    % 50; sct_def is unchanged
% ```
    arguments (Input)
        solver % Holder of the defaults: a struct (the settings of GUILDA.config and the conditions of the solver, as built by get_options) or a solver object. Only read.
        sct_map (1,1) struct % One field per accepted Name-Value name. The value is the solver field it sets: a string ("MaxIteration"), a string array to set several fields, a dotted path into a struct property ("sct_ode.Events"), or a cell {field, fcn} where fcn converts the given value (e.g. Verbose=true -> Display="iter").
        nv          = struct() % Overrides of this call: the struct of an arguments block (opt.Name with no default, so only given names are fields) or a cell {Name1, Value1, ...}.
    end
    arguments (Output)
        sct_options % Effective settings, keyed by solver field name.
        sv_given % Accepted names given in this call, in sct_map spelling.
    end

    s_solver   = string(class(solver));
    sr_names   = string(fieldnames(sct_map)).';

    % Name-Value pairs of this call
    if isstruct(nv)
        sr_in = string(fieldnames(nv)).';
        c_in  = struct2cell(nv).';
    elseif iscell(nv)
        if mod(numel(nv), 2) ~= 0
            error(msg("GUILDA:resolve_options:InvalidPairs", char(s_solver)));
        end
        sr_in = string(nv(1:2:end));
        c_in  = nv(2:2:end);
    else
        error(msg("GUILDA:resolve_options:InvalidPairs", char(s_solver)));
    end

    % Stored defaults of every field the map refers to
    sct_options = struct();
    c_target  = cell(size(sr_names));
    for i = 1:numel(sr_names)
        [sv_path, f_convert] = map_entry(sct_map.(sr_names(i)));
        c_target{i} = {sv_path, f_convert};
        for path = sv_path
            sr_part = split(path, ".").';
            if ~has_field(solver, sr_part(1))
                error(msg("GUILDA:resolve_options:UnknownField", char(sr_names(i)), char(path), char(s_solver)));
            end
            if ~isfield(sct_options, sr_part(1))
                sct_options.(sr_part(1)) = solver.(sr_part(1));
            end
            if numel(sr_part) > 1 && ~has_path(sct_options.(sr_part(1)), sr_part(2:end))
                error(msg("GUILDA:resolve_options:UnknownField", char(sr_names(i)), char(path), char(s_solver)));
            end
        end
    end

    % Overrides (a repeated name: the last one wins)
    sv_given = strings(1,0);
    for k = 1:numel(sr_in)
        idx = find(strcmpi(sr_in(k), sr_names), 1);
        if isempty(idx)
            error(msg("GUILDA:resolve_options:UnknownName", char(sr_in(k)), char(s_solver), ...
                      char(join(sr_names, ", "))));
        end
        [sv_path, f_convert] = c_target{idx}{:};
        val = c_in{k};
        if ~isempty(f_convert)
            val = f_convert(val);
        end
        for path = sv_path
            sr_part   = cellstr(split(path, ".").');
            sct_options = setfield(sct_options, sr_part{:}, val);
        end
        sv_given = [sv_given(sv_given ~= sr_names(idx)), sr_names(idx)];
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

function l = has_field(solver, s_name)
    if isstruct(solver)
        l = isfield(solver, s_name);
    else
        l = isprop(solver, s_name);
    end
end

function l = has_path(s, sr_part)
    l = true;
    for p = sr_part
        if ~isstruct(s) || ~isfield(s, p)
            l = false;
            return
        end
        s = s.(p);
    end
end
