function c_out = show_text(s_text, n_out)
% Displays s_text, or returns it when the caller asked for one output (disp_* methods)
    arguments (Input)
        s_text (1,1) string  % Text of the view.
        n_out  (1,1) double  % nargout of the disp_ method.
    end
    arguments (Output)
        c_out cell           % {} when displayed, {s_text} when returned.
    end
    if n_out == 0
        disp(s_text)
        c_out = {};
    else
        c_out = {s_text};
    end
end
