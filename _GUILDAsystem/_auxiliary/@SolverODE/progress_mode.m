function str = progress_mode(val)
% Value of the Name-Value option Progress: true -> "dialog", false -> "none"
    arguments (Input)
        val  % Value of Progress: true, false, "dialog", "disp" or "none".
    end
    arguments (Output)
        str  % Progress mode ("dialog", "disp" or "none").
    end
    if islogical(val) || isnumeric(val)
        if val
            str = "dialog";
        else
            str = "none";
        end
    else
        str = string(val);
    end
end
