function [value, l_ok, s_wait] = eval_depend(sv_expr, sv_depend, sct_field, history, a_object)
% Value of a choices or default expression that refers to other inputs of the method, for their current values.
%
% The expression names each input it refers to as `arg.<name>` (build_form writes it so).
% The current value of each such field is read from its widget (or the value shown first
% while it is not drawn): the selected tag or tags, the text of a string field, the number of
% a number field ("auto" and "none" as the numbers they stand for), and for an expression
% field the default when its text is the default, else a variable of the history followed
% only by properties and numeric indices (`sc`, `net.a_Scenario{2}`); nothing else is
% evaluated, so no method runs. The alternatives in sv_expr (`From.Time`, `[0, 10]`) are
% tried in order and the first that evaluates gives the value. While a field it refers to is
% empty or cannot be read, nothing is evaluated and s_wait asks for that field.
    arguments (Input)
        sv_expr (1,:) string     % Alternatives of the expression, with `arg.<name>` for the inputs.
        sv_depend (1,:) string   % Names of the inputs it refers to.
        sct_field struct         % Fields of the form (sct_field of build_form; one not made yet counts as empty).
        history                  % HistoryGUILDA of the call, or [].
        a_object                 % Object of the call (obj in the expression), or [].
    end
    arguments (Output)
        value                    % Value of the first alternative that evaluates ([] for none).
        l_ok (1,1) logical       % True when an alternative was evaluated.
        s_wait (1,1) string      % "Select <label> first" while it cannot be evaluated, else "".
    end
    arg = struct();
    sv_name = string({sct_field.name});
    sv_missing = strings(1, 0);
    for s_name = sv_depend
        i_field = find(sv_name == s_name, 1);
        if isempty(i_field)    % an input after it, not made yet (build_form evaluates it again after)
            sv_missing(end+1) = s_name;    %#ok<AGROW>
            continue
        end
        sct = sct_field(i_field);
        v = sct.shown;
        if sct.l_built
            v = sct.h.Value;
        end
        switch sct.widget
            case "tags"
                field = reshape(string(v), 1, []);
                l_field = true;
            case {"choice", "string"}
                field = string(v);
                l_field = field ~= "";
            case "tagtext"
                field = parse_tags(string(v));
                l_field = ~isempty(field);
            case "logical"
                field = logical(v);
                l_field = true;
            case "flag"
                field = string(v) == "true";
                l_field = string(v) ~= "";
            case "number"
                s_text = strtrim(string(v));
                if s_text == sct.s_auto && ~isempty(sct.r_auto)
                    [field, l_field] = deal(sct.r_auto, true);
                elseif s_text == "none" && ~isempty(sct.r_none)
                    [field, l_field] = deal(sct.r_none, true);
                else
                    [field, l_field] = str2num(char(s_text), Evaluation="restricted");    %#ok<ST2NM>
                    l_field = l_field && s_text ~= "" && (isnumeric(field) || islogical(field));
                end
            otherwise    % expression
                s_text = strtrim(string(v));
                if s_text == sct.s_base
                    [field, l_field] = eval_text(sct.s_default, a_object);
                else    % a variable with properties and numeric indices only
                    [field, l_field] = deal([], false);
                    c_tok = regexp(s_text, "^([A-Za-z]\w*)((?:\.[A-Za-z]\w*|\{\d+\}|\(\d+\))*)$", "tokens", "once");
                    if ~isempty(c_tok) && ~isempty(history)
                        try
                            field = history.get_variable(c_tok{1});
                            l_field = true;
                            for s_step = string(regexp(c_tok{2}, "\.[A-Za-z]\w*|\{\d+\}|\(\d+\)", "match"))
                                s_key = extractAfter(s_step, 1);
                                switch extractBefore(s_step, 2)
                                    case "."
                                        if isscalar(field) && ((isobject(field) && isprop(field, s_key)) || (isstruct(field) && isfield(field, s_key)))
                                            field = field.(s_key);
                                        else
                                            l_field = false;
                                            break
                                        end
                                    case "{"
                                        field = field{str2double(extractBefore(s_key, strlength(s_key)))};
                                    otherwise
                                        field = field(str2double(extractBefore(s_key, strlength(s_key))));
                                end
                            end
                        catch    % no such variable or index
                            l_field = false;
                        end
                    end
                end
        end
        if ~l_field
            sv_missing(end+1) = sct.s_label;    %#ok<AGROW>
        end
        arg.(s_name) = field;
    end
    value = [];
    l_ok = false;
    s_wait = "";
    if isempty(sv_missing)
        for s_expr = sv_expr
            [value, l_ok] = eval_text(s_expr, a_object, arg);
            if l_ok
                return
            end
        end
        sv_missing = arrayfun(@(s) sct_field(find(sv_name == s, 1)).s_label, sv_depend);    % all made: none was missing
    end
    s_wait = "Select " + join(sv_missing, ", ") + " first";
end
