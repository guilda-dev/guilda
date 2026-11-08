function Deprecated(key, varargin)
% Warn that an old form of the public API was used.
%
% `Deprecated(KEY, ARG1, ...)` issues the warning of "GUILDA:Deprecated:<KEY>" (text in
% SystemTools/GUILDA/en/Deprecated.xml) once per MATLAB session.
%
% - Show them again: `clear Deprecated`
%
% Keys: BusBaseMVA, BusBaseMVAMismatch,
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
% - A removed form that cannot keep working is an error in the file that detects it, with
%   its text in the XML of that file: error(msg("GUILDA:<File>:KEY", ...)).
%
% See also legacy_output
    arguments (Input)
        key       % KEY of the deprecated form (see above).
    end
    arguments (Input, Repeating)
        varargin  % Arguments of the message text.
    end
    persistent sv_shown
    if isempty(sv_shown)
        sv_shown = strings(0,1);
    end
    id   = 'GUILDA:Deprecated:' + string(key);
    args = cellfun(@(a) char(string(a)), varargin, "UniformOutput", false);
    if ~any(sv_shown == id)
        sv_shown(end+1,1) = id;
        show_msg("warning", id, args{:});
    end
end
