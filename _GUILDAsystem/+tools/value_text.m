function s = value_text(val)
% Return a short text of a value for a message, such as an edit report.
%
% Numbers, logicals and text of up to 4 elements are written out (mat2str, 6 digits);
% larger values and other classes are written as their size and class.
%
% <@Examples>
% ```matlab
% tools.value_text(0.1)          % "0.1"
% tools.value_text(eye(3))       % "[3x3 double]"
% ```
%
% See also LayerPackage
    arguments (Input)
        val   % Value to describe.
    end
    arguments (Output)
        s (1,1) string   % Short text of the value.
    end
    if (isnumeric(val) || islogical(val)) && numel(val) <= 4
        s = string(mat2str(val, 6));
    elseif isstring(val) && numel(val) <= 4
        s = string(mat2str(val));
    elseif ischar(val) && size(val,1) <= 1 && numel(val) <= 40
        s = """" + string(val) + """";
    else
        s = "[" + join(string(size(val)), "x") + " " + class(val) + "]";
    end
end
