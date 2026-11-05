function h = draw_cuboid_horizontal(ax, x0, y0, z0, radius, color, scale_x)
arguments (Input)
    ax           % Axes to draw in.
    x0           % X coordinate of the start.
    y0           % Y coordinate of the center.
    z0           % Z coordinate of the center.
    radius       % Height of the bar.
    color        % Face color.
    scale_x = [] % Length of the bar along x (1 when empty or omitted).
end
arguments (Output)
    h            % Patch drawn.
end
if nargin < 7 || isempty(scale_x)
    scale_x = 1;
end
wx = scale_x;
wy = 0.005;
hgt = radius;
x = x0 + 0.5*wx*(1+[-1 -1  1  1 -1 -1  1  1]);
y = y0 + 0.5*wy*[-1  1  1 -1 -1  1  1 -1];
z = z0 + 0.5*hgt*[-1 -1 -1 -1 1 1 1 1];
f = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
h = patch(ax, 'Vertices', [x(:) y(:) z(:)], 'Faces', f, ...
    'FaceColor', color, ...
    'EdgeColor', [0.15 0.15 0.15], ...
    'AmbientStrength', 0.22, ...
    'DiffuseStrength', 0.68, ...
    'SpecularStrength', 0.88, ...
    'SpecularExponent', 30, ...
    'BackFaceLighting', 'reverselit', ...
    'HandleVisibility', 'off');
end
