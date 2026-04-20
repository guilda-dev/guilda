function h = draw_arrow_cone(ax, tip_xyz, dir_vec, cone_len, cone_radius, color)
L = norm(dir_vec);
if L < eps
    h = gobjects(1,1);
    return
end

dir = dir_vec / L;
base = tip_xyz - cone_len * dir;

ref = [0 0 1];
if abs(dot(dir, ref)) > 0.9
    ref = [0 1 0];
end
u = cross(dir, ref);
u = u / norm(u);
w = cross(dir, u);

[xc, yc, zc] = cylinder([cone_radius 0], 22);
zc = zc * cone_len;

X = zeros(size(xc));
Y = zeros(size(yc));
Z = zeros(size(zc));
for i = 1:numel(xc)
    p = base + xc(i) * u + yc(i) * w + zc(i) * dir;
    X(i) = p(1);
    Y(i) = p(2);
    Z(i) = p(3);
end

h = surf(ax, X, Y, Z, ...
    'FaceColor', color, ...
    'EdgeColor', 'none', ...
    'FaceLighting', 'gouraud', ...
    'AmbientStrength', 0.22, ...
    'DiffuseStrength', 0.68, ...
    'SpecularStrength', 0.88, ...
    'SpecularExponent', 30, ...
    'BackFaceLighting', 'reverselit', ...
    'HandleVisibility', 'off');
end
