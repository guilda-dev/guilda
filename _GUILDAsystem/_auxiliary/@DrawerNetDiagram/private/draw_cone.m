function h = draw_cone(ax, x0, y0, z0, radius, color, theta_offset)
    % Draw cone in specified direction
    % theta_offset: rotation angle in radians
    %   pi/2   = upward (^)
    %  -pi/2   = downward (v)
    %   0      = rightward (>)
    %   pi     = leftward (<)
    
    hgt = 2.0 * radius;
    z_top = z0 + 0.8 * radius;
    z_apex = z_top - hgt;

    theta = (0:2) * (2*pi/3) + theta_offset;
    x_base = x0 + radius * cos(theta);
    y_base = y0 + radius * sin(theta);

    v = [
        x_base(1), y_base(1), z_top;
        x_base(2), y_base(2), z_top;
        x_base(3), y_base(3), z_top;
        x0,        y0,        z_apex
    ];

    f = [
        1 2 3;
        1 2 4;
        2 3 4;
        3 1 4
    ];

    h = patch(ax, 'Vertices', v, 'Faces', f, ...
        'FaceColor', color, ...
        'EdgeColor', 'none', ...
        'AmbientStrength', 0.20, ...
        'DiffuseStrength', 0.70, ...
        'SpecularStrength', 0.92, ...
        'SpecularExponent', 34, ...
        'BackFaceLighting', 'reverselit', ...
        'HandleVisibility', 'off');
end
