function place_label(h_text, rv_start, rv_direction, r_length, s_text, r_value)
% Put a value label just beyond the tip of an arrow; hide it when the value is about zero.
%
% In 2D the alignment follows the direction so that the text stays clear of the arrow; in
% 3D the text is centred.
    arguments (Input)
        h_text                      % Text object.
        rv_start (1,:) double       % Start point of the arrow, (x, y) or (x, y, z).
        rv_direction (1,:) double   % Unit vector towards the tip.
        r_length (1,1) double       % Length of the arrow.
        s_text (1,1) string         % Text of the label.
        r_value (1,1) double        % Value shown; |value| < 5e-3 hides the label.
    end
    l_3d = numel(rv_start) == 3;
    if ~(abs(r_value) >= 5e-3)
        set(h_text, "String", "", "Position", nan(1, 3));
        return
    end
    if l_3d
        rv_pos = rv_start + (max(r_length, 0.08) + 0.04) * rv_direction;
        set(h_text, "String", s_text, "Position", rv_pos, ...
            "HorizontalAlignment", "center", "VerticalAlignment", "middle");
        return
    end
    rv_pos = rv_start + (max(r_length, 0.08) + 0.03) * rv_direction;
    sv_h = ["right", "center", "left"];
    sv_v = ["top", "middle", "bottom"];
    set(h_text, "String", s_text, "Position", [rv_pos 0], ...
        "HorizontalAlignment", sv_h(2 + (rv_direction(1) > 0.35) - (rv_direction(1) < -0.35)), ...
        "VerticalAlignment",   sv_v(2 + (rv_direction(2) > 0.35) - (rv_direction(2) < -0.35)));
end
