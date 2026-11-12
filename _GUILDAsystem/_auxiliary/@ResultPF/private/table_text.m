function s = table_text(tab)
% Text of a table as MATLAB displays it, without the link markup of the desktop
    arguments (Input)
        tab table   % Table to show.
    end
    arguments (Output)
        s (1,1) string  % Display text.
    end
    s = string(formattedDisplayText(tab, "SuppressMarkup", true));
end
