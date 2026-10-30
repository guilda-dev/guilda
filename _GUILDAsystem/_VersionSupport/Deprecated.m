function txt = Deprecated(key, varargin)
% Warn that an old form of the public API was used.
%
% `Deprecated(KEY, ARG1, ...)` issues the warning "GUILDA:Deprecated:<KEY>" (text in
% SystemTools/GUILDA/en/Deprecated.xml) once per MATLAB session.
% `TXT = Deprecated(KEY, ARG1, ...)` only returns the text (for errors).
%
% - Turn a warning off: `warning("off", "GUILDA:Deprecated:<KEY>")`
% - Show them again: `clear Deprecated`
%
% Keys: ComponentBaseHz, ComponentBaseHzSet, BusBaseMVA, BusBaseMVAMismatch,
% CsvNetHandlerImport, CsvNetHandlerExport (see Deprecated.xml for all).
%
% Convention for a new deprecated form:
%
% - KEY is UpperCamelCase, <Owner><What> (e.g. BusBaseMVA, OptimizePowerflowTuple).
%   Add <entry key="KEY"> to Deprecated.xml; the text says what is deprecated and what
%   to use instead.
% - Call it from _VersionSupport/ only (a wrapper, a hook helper such as
%   v3_bus_baseMVA, or legacy_output). Core code reaches it through one line tagged
%   % COMPAT(v<N>), where <N> is the old major version.
% - A removed form that cannot keep working is an error with the same ID:
%   error('GUILDA:Deprecated:KEY', '%s', Deprecated("KEY", ...)).
%
% The input `key` is the KEY above and `varargin` the arguments of the message text.
%
% See also legacy_output
    arguments (Output)
        txt   % Text of the message (only when an output is requested; no warning then).
    end
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
