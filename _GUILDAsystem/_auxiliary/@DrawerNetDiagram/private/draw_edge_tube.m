function h = draw_edge_tube(ax, p_from, p_to, radius, color, mid_pts)

pts = [p_from; mid_pts; p_to];
if size(pts,1) > 1
    keep = [true; sqrt(sum(diff(pts,1,1).^2,2)) > eps];
    pts = pts(keep, :);
end
if size(pts,1) < 2
    h = plot3(ax, pts(1,1), pts(1,2), pts(1,3), '.', 'Color', color, 'HandleVisibility', 'off');
    return
end

n_theta = 20;
theta = linspace(0, 2*pi, n_theta);
n_sec = size(pts, 1);
X = zeros(n_sec, n_theta);
Y = zeros(n_sec, n_theta);
Z = zeros(n_sec, n_theta);

for i_sec = 1:n_sec
    if i_sec == 1
        t_vec = pts(2,:) - pts(1,:);
    elseif i_sec == n_sec
        t_vec = pts(end,:) - pts(end-1,:);
    else
        t_vec = pts(i_sec+1,:) - pts(i_sec-1,:);
    end

    L = norm(t_vec);
    if L < eps
        if i_sec < n_sec
            t_vec = pts(i_sec+1,:) - pts(i_sec,:);
            L = norm(t_vec);
        end
        if L < eps && i_sec > 1
            t_vec = pts(i_sec,:) - pts(i_sec-1,:);
            L = norm(t_vec);
        end
        if L < eps
            t_vec = [1 0 0];
            L = 1;
        end
    end
    dir = t_vec / L;

    ref = [0 0 1];
    if abs(dot(dir, ref)) > 0.9
        ref = [0 1 0];
    end
    u = cross(dir, ref);
    if norm(u) < eps
        ref = [1 0 0];
        u = cross(dir, ref);
    end
    u = u / norm(u);
    w = cross(dir, u);

    for j = 1:n_theta
        c = cos(theta(j));
        s = sin(theta(j));
        offset = radius * (c*u + s*w);
        p = pts(i_sec,:) + offset;
        X(i_sec, j) = p(1);
        Y(i_sec, j) = p(2);
        Z(i_sec, j) = p(3);
    end
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
