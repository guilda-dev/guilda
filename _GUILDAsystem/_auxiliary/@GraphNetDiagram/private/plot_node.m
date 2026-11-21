function h = plot_node(ax, center_xyz, shape, len, radius, color, nodedata)
% Draw the solid of a bus or a component at its center (graph parameters Shape and Length).
    arguments (Input)
        ax          % Axes to draw in.
        center_xyz  % Position of the center [x y z].
        shape       % Shape: "hbar", "vbar", "circle", "square", "^", "v", "<", ">" or "none" (others: a cube).
        len         % Length of a bar ("hbar", "vbar"); not used by the other shapes.
        radius      % Size of the solid.
        color       % Face color.
        nodedata    % UserData stored on the drawn object (struct with Type and Index).
    end
    arguments (Output)
        h  % Graphics object drawn.
    end
    x0 = center_xyz(1);
    y0 = center_xyz(2);
    z0 = center_xyz(3);

    switch string(shape)
        case "vbar"
            h = draw_cuboid_vertical(ax, x0, y0, z0, radius, color, len);
        case "hbar"
            h = draw_cuboid_horizontal(ax, x0, y0, z0, radius, color, len);
        case "circle"
            h = draw_sphere(ax, x0, y0, z0, radius*2, [0.6110 0.4660 0.1250]);
        case "^"
            h = draw_cone(ax, x0, y0+radius, z0-radius, radius*2, [0.7170 0.1920 0.1720], pi/2);
        case "v"
            h = draw_cone(ax, x0, y0-radius, z0-radius, radius*2, [0.7170 0.1920 0.1720], -pi/2);
        case ">"
            h = draw_cone(ax, x0+radius, y0, z0-radius, radius*2, [0.7170 0.1920 0.1720], 0);
        case "<"
            h = draw_cone(ax, x0-radius, y0, z0-radius, radius*2, [0.7170 0.1920 0.1720], pi);
        case "none"
            h = not_draw();
        otherwise
            h = draw_cuboid(ax, x0, y0, z0, radius, color);
    end
    h.UserData = nodedata;
end
