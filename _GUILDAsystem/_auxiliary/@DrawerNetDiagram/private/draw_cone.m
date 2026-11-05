function h = draw_cone(ax, x0, y0, z0, radius, color, theta_offset)
    % Draw cone in specified direction
    arguments (Input)
        ax            % Axes to draw in.
        x0            % X coordinate of the center.
        y0            % Y coordinate of the center.
        z0            % Z coordinate of the center.
        radius        % Radius of the cone base.
        color         % Face color.
        theta_offset  % [rad] Rotation angle: pi/2 up (^), -pi/2 down (v), 0 right (>), pi left (<).
    end
    arguments (Output)
        h             % Patch drawn.
    end
    
    hgt    = 2.0 * radius;
    z_top  = z0 + 0.8 * radius;
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
