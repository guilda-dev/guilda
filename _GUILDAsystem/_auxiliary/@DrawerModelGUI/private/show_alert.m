function show_alert(h, s_message, s_title)
% Show an error message in an alert of the figure of h; a hidden figure gets a warning instead.
%
% uialert needs a visible figure (it errors on a hidden one, e.g. in tests).
    arguments (Input)
        h          % Component of the figure.
        s_message  % Message.
        s_title    % Title of the alert.
    end
    arguments (Output)
    end
    h_fig = ancestor(h, "figure");
    if h_fig.Visible
        uialert(h_fig, s_message, s_title);
    else
        warning(msg("GUILDA:DrawerModelGUI:HiddenAlert", s_title, s_message))
    end
end
