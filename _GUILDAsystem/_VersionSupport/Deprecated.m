function txt = Deprecated(key, varargin)
% DEPRECATED warns that an old form of the public API was used.
%    Deprecated(KEY, ARG1, ...) issues the warning "GUILDA:Deprecated:<KEY>"
%    (text in SystemTools/GUILDA/en/Deprecated.xml) once per MATLAB session.
%    TXT = Deprecated(KEY, ARG1, ...) only returns the text (for errors).
%
%    Turn a warning off : warning("off", "GUILDA:Deprecated:<KEY>")
%    Show them again    : clear Deprecated
%
%    Keys: ComponentBaseHz, ComponentBaseHzSet, BusBaseMVA, BusBaseMVAMismatch
    persistent sv_shown
    if isempty(sv_shown)
        sv_shown = strings(0,1);
    end
    id   = 'GUILDA:Deprecated:' + string(key);
    args = cellfun(@(a) char(string(a)), varargin, "UniformOutput", false);
    str  = msg(char(id), args{:});
    if nargout > 0
        txt = str;
        return
    end
    if ~any(sv_shown == id)
        sv_shown(end+1,1) = id;
        warning(char(id), '%s', str);
    end
end
