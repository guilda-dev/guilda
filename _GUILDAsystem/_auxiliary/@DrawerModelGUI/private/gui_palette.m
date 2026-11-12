function sct_color = gui_palette()
% Colors of the GUI: a fixed light theme based on the GUILDA logo, set on every component.
%
% The colors do not follow the MATLAB theme (a dark theme would leave parts unreadable).
    arguments (Input)
    end
    arguments (Output)
        sct_color (1,1) struct  % RGB triplets in [0,1]; sct_kind holds the background of the child cards.
    end
    sct_color = struct( ...
        "rv_blue",           hex2rgb("#005BAA"), ...  % Header band and links (logo blue).
        "rv_lime",           hex2rgb("#D4DE24"), ...  % Accent lines only (logo lime).
        "rv_background",     hex2rgb("#F4F6F9"), ...  % Background of the GUI.
        "rv_card",           hex2rgb("#FBFCFD"), ...  % Panels and tables.
        "rv_stripe",         hex2rgb("#F2F5F9"), ...  % Alternate table rows.
        "rv_text",           hex2rgb("#23303F"), ...  % Text.
        "rv_subtext",        hex2rgb("#5B6B7D"), ...  % Notes.
        "rv_header_text",    [1 1 1], ...             % Text on the header band.
        "rv_header_subtext", hex2rgb("#D6E4F2"), ...  % Notes on the header band.
        "rv_stale_text",     hex2rgb("#B26A00"), ...  % Stale warning text.
        "rv_stale_back",     hex2rgb("#FFF4E0"));     % Stale warning background.
    sct_color.sct_kind = struct( ...
        "Bus",              hex2rgb("#E3EEF8"), ...  % Blue.
        "Branch",           hex2rgb("#ECEFF3"), ...  % Gray.
        "Component",        hex2rgb("#F1F5D2"), ...  % Lime.
        "LocalController",  hex2rgb("#FBEADB"), ...  % Warm.
        "GlobalController", hex2rgb("#ECE6F5"), ...  % Purple.
        "Scenario",         hex2rgb("#E0F2EE"), ...  % Teal.
        "Other",            hex2rgb("#ECEFF3"));     % Gray.
end

function rv_rgb = hex2rgb(s_hex)
% RGB triplet in [0,1] of a "#RRGGBB" color.
    arguments (Input)
        s_hex (1,1) string  % Color as "#RRGGBB".
    end
    arguments (Output)
        rv_rgb (1,3) double  % RGB triplet.
    end
    rv_rgb = double(hex2dec(reshape(char(extractAfter(s_hex, 1)), 2, 3).')).' / 255;
end
