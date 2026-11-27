function sct = read_model_help(s_class)
% Read the equations and the variable lists from the help of a model class.
%
% Reads the help comment of the classdef file (the comment lines right after the
% classdef line), not the code: a model with if/switch keeps the equations written in
% its help. The sections are the Markdown headings of the model help
% (see `component.generator.classical`):
%
% - `**State variables**`, `**Input signals**`, `**Output signals**`, `**Parameters**`:
%   bullets ``- `name` [unit]: description`` (the unit is optional; ``- `a`, `b`: ...``
%   gives one row per name; ``- none`` gives no row; an indented line continues the
%   bullet). A branch has only `**Parameters**`.
% - `**Equations**` (or `**Equation**`): the ```math blocks of the section.
%
% A section ends at the next `**...**` heading, a `<@...>` tag or the `See also` line.
% Only the class's own help is read (not that of its superclasses).
%
% <@Examples>
% ```matlab
% sct = tools.read_model_help("component.generator.classical");
% sct.Equations{1}          % LaTeX of the first math block
% sct.Variables             % Kind, Name, Unit, Description
% ```
%
% See also GUILDA.disp_equations, Component.disp_io, LocalController.disp_io
    arguments (Input)
        s_class (1,1) string  % Class name, with its package (e.g. "controller.avr.AVR_ST1").
    end
    arguments (Output)
        sct  % Struct: Class, File, Equations (string column, one LaTeX block per element), Text (string column: the lines of the Equations section, prose and math blocks), Variables (table Kind "x"|"u"|"y"|"para", Name, Unit, Description).
    end
    sct = struct("Class", s_class, "File", "", "Equations", strings(0,1), "Text", strings(0,1), ...
        "Variables", table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
                           'VariableNames', ["Kind","Name","Unit","Description"]));
    s_file = string(which(s_class));
    if s_file == "" || ~isfile(s_file)
        return
    end
    sct.File = s_file;

    % help comment: the comment lines after the classdef line, without the leading "% "
    sv_line = readlines(s_file, "EmptyLineRule", "read");
    i0 = find(startsWith(strtrim(sv_line), "classdef"), 1);
    if isempty(i0)
        return
    end
    sv_help = strings(0,1);
    for k = i0+1:numel(sv_line)
        s = strtrim(sv_line(k));
        if ~startsWith(s, "%")
            break
        end
        sv_help(end+1,1) = regexprep(extractAfter(s, 1), "^ ", ""); %#ok<AGROW>
    end

    % sections: a heading line "**Name**..." starts one; tags and See also end it
    sm_map  = ["state variables","x"; "input signals","u"; "output signals","y"; ...
               "parameters","para"; "equations","eq"; "equation","eq"];   % heading -> section kind
    sv_kind = strings(numel(sv_help),1);   % section of each line ("" outside the sections read)
    s_sec = "";
    for k = 1:numel(sv_help)
        tok = regexp(sv_help(k), "^\*\*([^*]+)\*\*", "tokens", "once");
        if ~isempty(tok)
            i = find(sm_map(:,1) == lower(strtrim(string(tok{1}))), 1);
            s_sec = "";
            if ~isempty(i)
                s_sec = sm_map(i,2);
            end
            if s_sec == "eq"   % keep the note after the heading, e.g. "(transducer, amplifier)"
                sv_help(k) = strtrim(regexprep(sv_help(k), "^\*\*[^*]+\*\*", ""));
                sv_kind(k) = s_sec;
            end
            continue
        elseif startsWith(sv_help(k), "<@") || startsWith(sv_help(k), "See also")
            s_sec = "";
        end
        sv_kind(k) = s_sec;
    end

    % Equations: the lines of the section and its math blocks
    sv_eq = sv_help(sv_kind == "eq");
    lv = strtrim(sv_eq) ~= "";   % without the blank lines at both ends
    if any(lv)
        sct.Text = sv_eq(find(lv,1):find(lv,1,"last"));
    end
    l_math = false;
    s_block = strings(0,1);
    for s = sct.Text'
        if ~l_math && strtrim(s) == "```math"
            l_math = true;
            s_block = strings(0,1);
        elseif l_math && strtrim(s) == "```"
            l_math = false;
            sct.Equations(end+1,1) = join(s_block, newline);
        elseif l_math
            s_block(end+1,1) = s; %#ok<AGROW>
        end
    end

    % Variables: one row per name of each bullet (continued by indented lines)
    sm = strings(0,4);
    for k = find(ismember(sv_kind, ["x","u","y","para"]))'
        if ~startsWith(sv_help(k), "- ")
            continue
        end
        s_text = extractAfter(sv_help(k), 2);
        j = k + 1;
        while j <= numel(sv_help) && sv_kind(j) == sv_kind(k) && startsWith(sv_help(j), "  ") && strtrim(sv_help(j)) ~= ""
            s_text = s_text + " " + strtrim(sv_help(j));
            j = j + 1;
        end
        tok = regexp(s_text, "^(?<name>(?:`[^`]+`(?:\s*,\s*|\s+and\s+)?)+)\s*(?<unit>(?:\[[^\]]*\])?)\s*:\s*(?<desc>.*)$", "names", "once");
        if isempty(tok)   % "- none" or a bullet without a name
            continue
        end
        c_name  = regexp(string(tok.name), "`([^`]+)`", "tokens");
        sv_name = reshape(string(cellfun(@(c) c{1}, c_name, "UniformOutput", false)), [], 1);
        n = numel(sv_name);
        sm = [sm; repmat(sv_kind(k),n,1), sv_name, repmat(strip(strip(string(tok.unit),"left","["),"right","]"),n,1), repmat(strtrim(string(tok.desc)),n,1)]; %#ok<AGROW>
    end
    sct.Variables = table(sm(:,1), sm(:,2), sm(:,3), sm(:,4), 'VariableNames', ["Kind","Name","Unit","Description"]);
end

