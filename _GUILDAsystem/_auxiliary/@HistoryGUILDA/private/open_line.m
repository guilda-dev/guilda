function open_line(obj, h)
% Open in the Editor the file of the method or function that the double-clicked `>>` line calls.
%
% The first call `<receiver>.<method>(` of the line is used, with the class of the receiver
% evaluated in the workspace of the log; otherwise the first `<function>(`. Nothing happens when no file is
% found (best effort).
    arguments (Input)
        obj  % The log.
        h    % List box of the view.
    end
    arguments (Output)
    end
    i_line = h.Value;     % the double click selects the line
    h.Value = [];
    if isempty(i_line) || ~iscell(h.Items) || isempty(h.UserData)
        return
    end
    s_code = h.UserData(i_line(1));
    s_file = "";
    tok = regexp(s_code, "([A-Za-z]\w*(?:\.\w+|\{[^}]*\})*)\.(\w+)\s*\(", "tokens", "once");
    if ~isempty(tok)
        try    % a method: the class of the receiver, then the file that defines the method
            sct = eval_workspace(obj.sct_variable, char("s__class = class(" + tok(1) + ");"));
            mc  = meta.class.fromName(sct.s__class);
            mm  = mc.MethodList(string({mc.MethodList.Name}) == tok(2));
            s_file = string(mm(1).FullPath);
        catch
        end
    end
    if ~endsWith(s_file, ".m")    % a function, e.g. PowerNetwork( or network.IEEE9bus(
        tok = regexp(s_code, "([A-Za-z][\w.]*)\s*\(", "tokens", "once");
        if ~isempty(tok)
            s_file = string(which(tok(1)));
        end
    end
    if endsWith(s_file, ".m")
        edit(s_file);
    end
end
