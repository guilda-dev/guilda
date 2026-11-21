function s = sample_text(obj, k, s_format)
% Text of sample k: the text of the data, else the sample name and value, else the time.
%
% With sv_sampleText of the data, its entry k. Else, with a sample name (e.g. "Step"), the
% name and the value of the sample ("Step 12"). Else the time written by
% sprintf(s_format, rv_t(k)) (e.g. "t = %.2f s").
    arguments (Input)
        obj
        k (1,1) double         % Index of the sample.
        s_format (1,1) string  % Format of the time (sprintf), used when the data names no samples.
    end
    arguments (Output)
        s (1,1) string  % Text of the sample.
    end
    if ~isempty(obj.sv_sampleText)
        s = obj.sv_sampleText(k);
    elseif obj.s_sampleName ~= ""
        s = obj.s_sampleName + " " + sprintf("%.4g", obj.rv_t(k));
    else
        s = sprintf(s_format, obj.rv_t(k));
    end
end
