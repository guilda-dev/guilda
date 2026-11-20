function sct_sig = read_signatures()
% Signatures of both functionSignatures.json files of GUILDA, merged into one struct.
%
% `_GUILDAsystem/resources/functionSignatures.json` (the classes of the model) and
% `_GUILDAsystem/_auxiliary/resources/functionSignatures.json` (the auxiliary classes, e.g.
% the Result classes) are decoded with jsondecode, whose field names are "<class>_<method>".
% A method in both files keeps the entry of the first one. A missing file is skipped. The
% merged struct is kept for the MATLAB session and read again when a file changes (its
% date or size), so opening a result GUI or pressing a button does not decode the files.
    arguments (Input)
    end
    arguments (Output)
        sct_sig (1,1) struct  % One field "<class>_<method>" per signature.
    end
    persistent sct_cache rv_stamp
    sv_file = fullfile(GUILDA.pwd(), "_GUILDAsystem", ["resources", fullfile("_auxiliary", "resources")], "functionSignatures.json");
    rv_now = zeros(1, 2 * numel(sv_file));
    for i = 1:numel(sv_file)
        sct_dir = dir(sv_file(i));
        if isscalar(sct_dir)
            rv_now(2 * i - [1 0]) = [sct_dir.datenum, sct_dir.bytes];
        end
    end
    if isstruct(sct_cache) && isequal(rv_stamp, rv_now)
        sct_sig = sct_cache;
        return
    end
    sct_sig = struct();
    for s_file = sv_file
        if ~isfile(s_file)
            continue
        end
        sct_file = jsondecode(fileread(s_file, "Encoding", "UTF-8"));
        sv_field = string(fieldnames(sct_file));
        for s_field = reshape(sv_field(~isfield(sct_sig, sv_field)), 1, [])
            sct_sig.(s_field) = sct_file.(s_field);
        end
    end
    sct_cache = sct_sig;
    rv_stamp  = rv_now;
end
