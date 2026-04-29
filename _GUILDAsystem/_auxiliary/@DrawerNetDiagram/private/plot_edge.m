function [h, h_arrow] = plot_edge(ax, path, radius, color, edgedata, type)

    h_arrow   = gobjects(1, 1);
    edge_type = string(type);
    h_main    = draw_edge_tube(ax, path, radius, color);
    h_main.UserData = edgedata;
    
    if size(path, 1) > 1
        keep = [true; sqrt(sum(diff(path, 1, 1).^2, 2)) > eps];
        path = path(keep, :);
    end

    if size(path, 1) >= 2
        cone_radius = 2 * radius;

        % From-side arrow: midpoint of first segment (path(1:2,:)).
        p_from_1 = path(1, :);
        p_from_2 = path(2, :);
        tip_from = p_from_1;
        dir_from = normalize(p_from_1 - p_from_2);
        cone_len = min(norm(p_from_1 - p_from_2) * 0.5, cone_radius);
        h_arrow_from = draw_arrow_cone(ax, tip_from, dir_from, cone_len, cone_radius, color);
        h_arrow_from.UserData = edgedata;

        % To-side arrow: midpoint of last segment (path(end-1:end,:)).
        p_to_1 = path(end-1, :);
        p_to_2 = path(end, :);
        tip_to = path(end, :);
        dir_to = normalize(p_to_2 - p_to_1);
        cone_len = min(norm(p_to_2 - p_to_1) * 0.5, cone_radius*2);
        h_arrow_to = draw_arrow_cone(ax, tip_to, dir_to, cone_len, cone_radius, color);
        h_arrow_to.UserData = edgedata;

        h_arrow = hggroup('Parent', ax, 'HandleVisibility', 'off');
        set(h_arrow_from, 'Parent', h_arrow);
        set(h_arrow_to,   'Parent', h_arrow);
        set(h_arrow,      'UserData', struct('From', h_arrow_from, 'To', h_arrow_to));
    end

    % For normal edges, return the tube handle directly so color updates
    % always target a concrete graphics primitive.
    if edge_type == "-"
        h = h_main;
        return
    end

    h_group = hggroup('Parent', ax, 'HandleVisibility', 'off');
    set(h_main, 'Parent', h_group);

    if edge_type == "-oo-"
        edge_type = "-oo";
    end

    if edge_type == "oo-" || edge_type == "-oo"
        if size(path, 1) < 2
            h = h_group;
            return
        end

        sphere_radius = min(max(radius * 3, radius + eps), 5);
        d1 = 0.05 + sphere_radius / 2;
        d2 = 0.05 + sphere_radius;
        
        if edge_type == "oo-"
            % Place two spheres near the from terminal, along the path
            c1 = get_point_on_path(path, d1);
            c2 = get_point_on_path(path, d2);
        else
            % Place two spheres near the to terminal, along the path
            % Measure distance from the to terminal in reverse
            c1 = get_point_on_path_from_end(path, d1);
            c2 = get_point_on_path_from_end(path, d2);
        end

        h1 = draw_sphere(ax, c1(1), c1(2), c1(3), sphere_radius, color);
        h2 = draw_sphere(ax, c2(1), c2(2), c2(3), sphere_radius, color);
        h1.UserData = edgedata;
        h2.UserData = edgedata;
        set(h1, 'Parent', h_group);
        set(h2, 'Parent', h_group);
    end

    h = h_group;
end

function point = get_point_on_path(path, distance)
    % Returns point at specified distance along path from start
    if size(path, 1) < 2
        point = path(1, :);
        return
    end
    
    diffs = diff(path, 1, 1);
    segment_lengths = sqrt(sum(diffs.^2, 2));
    cumulative_lengths = [0; cumsum(segment_lengths)];
    total_length = cumulative_lengths(end);
    
    if distance >= total_length
        point = path(end, :);
        return
    end
    
    idx = find(cumulative_lengths <= distance, 1, 'last');
    if idx >= length(cumulative_lengths)
        point = path(end, :);
        return
    end
    
    remaining_distance = distance - cumulative_lengths(idx);
    segment_length = segment_lengths(idx);
    if segment_length < eps
        point = path(idx, :);
        return
    end
    
    t = remaining_distance / segment_length;
    point = path(idx, :) + t * (path(idx+1, :) - path(idx, :));
end

function point = get_point_on_path_from_end(path, distance)
    % Returns point at specified distance along path from end
    if size(path, 1) < 2
        point = path(end, :);
        return
    end
    
    diffs = diff(path, 1, 1);
    segment_lengths = sqrt(sum(diffs.^2, 2));
    cumulative_lengths = [0; cumsum(segment_lengths)];
    total_length = cumulative_lengths(end);
    
    distance_from_start = max(0, total_length - distance);
    
    if distance_from_start <= 0
        point = path(1, :);
        return
    end
    
    idx = find(cumulative_lengths <= distance_from_start, 1, 'last');
    if idx >= length(cumulative_lengths)
        point = path(end, :);
        return
    end
    
    remaining_distance = distance_from_start - cumulative_lengths(idx);
    segment_length = segment_lengths(idx);
    if segment_length < eps
        point = path(idx, :);
        return
    end
    
    t = remaining_distance / segment_length;
    point = path(idx, :) + t * (path(idx+1, :) - path(idx, :));
end


function vec_normalized = normalize(vec)
    % Normalize vector
    mag = norm(vec);
    if mag < eps
        vec_normalized = [1, 0, 0];
    else
        vec_normalized = vec / mag;
    end
end