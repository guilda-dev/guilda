function load_sample_label(obj, sct_data)
% Read the optional sample name and per-sample text of the data (after rv_t is set).
%
% Called by load_data of a subclass once rv_t holds the samples of the new data. The
% fields of sct_data are
%
% - `s_sampleName` (optional, default ""): name of the samples, e.g. "Step" when the
%   samples are the steps of a continuation power flow; "" means time in seconds.
% - `sv_sampleText` (optional, 1 x n_t): the text shown for each sample, e.g.
%   "Step 12 (λ = 0.734)"; empty for the default text (see sample_text).
%
% Without these fields the samples are times, as before.
    arguments (Input)
        obj
        sct_data (1,1) struct  % Data of the graph (see the class help of the subclass).
    end
    s_name = "";
    if isfield(sct_data, "s_sampleName") && ~isempty(sct_data.s_sampleName)
        s_name = sct_data.s_sampleName;
        if ~((isstring(s_name) || ischar(s_name)) && isscalar(string(s_name)) && ~ismissing(string(s_name)))
            error(msg("GUILDA:GraphBase:SampleLabel", "s_sampleName", "a text, e.g. ""Step"""));
        end
    end
    sv_text = strings(1, 0);
    if isfield(sct_data, "sv_sampleText") && ~isempty(sct_data.sv_sampleText)
        sv_text = sct_data.sv_sampleText;
        if ~((isstring(sv_text) || iscellstr(sv_text)) && numel(sv_text) == numel(obj.rv_t))
            error(msg("GUILDA:GraphBase:SampleLabel", "sv_sampleText", "one text per sample (" + numel(obj.rv_t) + ")"));
        end
        sv_text = reshape(string(sv_text), 1, []);
        sv_text(ismissing(sv_text)) = "";
    end
    obj.s_sampleName  = string(s_name);
    obj.sv_sampleText = sv_text;
end
