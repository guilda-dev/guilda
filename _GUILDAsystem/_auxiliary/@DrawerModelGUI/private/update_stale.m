function update_stale(h_stale, a_target)
% Write the stale state of the model into the label: each stale tag with its first message.
%
% A stale model is shown in the warning colors; "Stale: none" in the note color of the header.
    arguments (Input)
        h_stale   % Label of the stale state.
        a_target  % Model shown.
    end
    arguments (Output)
    end
    sct_color = gui_palette();
    sct_stale = a_target.sct_stale;
    sv_line = strings(0,1);
    for s_tag = string(fieldnames(sct_stale)).'
        sv_msg = sct_stale.(s_tag);
        if isempty(sv_msg)
            continue
        end
        s_line = s_tag + ": " + sv_msg(1);
        if numel(sv_msg) > 1
            s_line = s_line + " (+" + (numel(sv_msg)-1) + " more)";
        end
        sv_line(end+1,1) = s_line; %#ok<AGROW>
    end
    if isempty(sv_line)
        h_stale.Text = "Stale: none";
        h_stale.FontColor = sct_color.rv_header_subtext;
        h_stale.BackgroundColor = sct_color.rv_blue;
    else
        h_stale.Text = ["Stale:"; "  " + sv_line];
        h_stale.FontColor = sct_color.rv_stale_text;
        h_stale.BackgroundColor = sct_color.rv_stale_back;
    end
end
