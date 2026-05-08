function h = draw_edge_tube(ax, path, radius, color)
    
    % 重複する点の削除
    if size(path,1) > 1
        keep = [true; sqrt(sum(diff(path,1,1).^2,2)) > eps];
        path = path(keep, :);
    end
    
    if size(path,1) < 2
        h = plot3(ax, path(1,1), path(1,2), path(1,3), '.', 'Color', color, 'HandleVisibility', 'off');
        return
    end

    n_path = size(path, 1);
    n_theta = 40; % 断面の円の解像度
    theta = linspace(0, 2*pi, n_theta);
    
    % surfに渡すための単一のグリッド座標
    X = zeros(n_path, n_theta);
    Y = zeros(n_path, n_theta);
    Z = zeros(n_path, n_theta);

    % --- 1. 各線分の方向ベクトルを計算 ---
    V = zeros(n_path-1, 3);
    for i = 1:n_path-1
        V(i,:) = path(i+1,:) - path(i,:);
        L = norm(V(i,:));
        if L > eps
            V(i,:) = V(i,:) / L;
        else
            V(i,:) = [1 0 0];
        end
    end

    % --- 2. 断面の基準ベクトル(U, W)を計算 (ねじれ防止: RMF) ---
    U = zeros(n_path-1, 3);
    W = zeros(n_path-1, 3);
    
    % 最初(1つ目)の線分のベクトル
    ref = [0 0 1];
    if abs(dot(V(1,:), ref)) > 0.9
        ref = [0 1 0];
    end
    U(1,:) = cross(V(1,:), ref);
    U(1,:) = U(1,:) / norm(U(1,:));
    W(1,:) = cross(V(1,:), U(1,:));
    
    % 2番目以降の線分は、直前のベクトルから回転させて引き継ぐ
    for i = 1:n_path-2
        axis_rot = cross(V(i,:), V(i+1,:));
        cos_a = dot(V(i,:), V(i+1,:));
        
        if norm(axis_rot) > eps && cos_a > -1 + eps
            % ロドリゲスの回転公式で滑らかに回転
            axis_rot = axis_rot / norm(axis_rot);
            sin_a = sqrt(1 - cos_a^2);
            t_rot = 1 - cos_a;
            x = axis_rot(1); y = axis_rot(2); z = axis_rot(3);
            R = [t_rot*x*x + cos_a,     t_rot*x*y - sin_a*z,   t_rot*x*z + sin_a*y;
                 t_rot*x*y + sin_a*z,   t_rot*y*y + cos_a,     t_rot*y*z - sin_a*x;
                 t_rot*x*z - sin_a*y,   t_rot*y*z + sin_a*x,   t_rot*z*z + cos_a];
            U(i+1,:) = (R * U(i,:)')';
        else
            U(i+1,:) = U(i,:);
        end
        U(i+1,:) = U(i+1,:) / norm(U(i+1,:));
        W(i+1,:) = cross(V(i+1,:), U(i+1,:));
    end

    % --- 3. 各ノードの頂点座標を計算 (マイタージョイント処理) ---
    for i = 1:n_path
        if i == 1
            % 始点: そのまま垂直な断面
            for j = 1:n_theta
                offset = radius * (cos(theta(j))*U(1,:) + sin(theta(j))*W(1,:));
                p = path(1,:) + offset;
                X(1, j) = p(1); Y(1, j) = p(2); Z(1, j) = p(3);
            end
        elseif i == n_path
            % 終点: そのまま垂直な断面
            for j = 1:n_theta
                offset = radius * (cos(theta(j))*U(n_path-1,:) + sin(theta(j))*W(n_path-1,:));
                p = path(n_path,:) + offset;
                X(n_path, j) = p(1); Y(n_path, j) = p(2); Z(n_path, j) = p(3);
            end
        else
            % 関節: 2つの筒が交差する平面（二等分面）で斜めにカットする
            v_in = V(i-1,:);
            v_out = V(i,:);
            T = v_in + v_out; % 交差平面の法線ベクトル
            
            if norm(T) < eps
                T = v_in; 
            else
                T = T / norm(T);
            end
            
            for j = 1:n_theta
                % ベースとなる手前のチューブの真円断面
                offset_base = radius * (cos(theta(j))*U(i-1,:) + sin(theta(j))*W(i-1,:));
                
                % 交差平面にぶつかるまでチューブの方向に頂点を延長(伸縮)させる
                denominator = dot(v_in, T);
                if abs(denominator) > eps
                    dt = -dot(offset_base, T) / denominator;
                else
                    dt = 0;
                end
                
                p = path(i,:) + offset_base + (dt * v_in);
                X(i, j) = p(1); Y(i, j) = p(2); Z(i, j) = p(3);
            end
        end
    end

    % --- 4. 1つのsurfとして描画 ---
    h = surf(ax, X, Y, Z, ...
        'FaceColor', color, ...
        'EdgeColor', 'none', ...
        'FaceLighting', 'gouraud', ...
        'AmbientStrength', 0.22, ...
        'DiffuseStrength', 0.68, ...
        'SpecularStrength', 0.88, ...
        'SpecularExponent', 30, ...
        'BackFaceLighting', 'reverselit', ...
        'HandleVisibility', 'off',...
        'FaceAlpha', 0.99);
end

% function h = draw_edge_tube(ax, p_from, p_to, radius, color, mid_path)
% 
% path = [p_from; mid_path; p_to];
% if size(path,1) > 1
%     keep = [true; sqrt(sum(diff(path,1,1).^2,2)) > eps];
%     path = path(keep, :);
% end
% if size(path,1) < 2
%     h = plot3(ax, path(1,1), path(1,2), path(1,3), '.', 'Color', color, 'HandleVisibility', 'off');
%     return
% end
% 
% n_theta = 50;
% theta = linspace(0, 2*pi, n_theta);
% n_sec = size(path, 1);
% X = zeros(n_sec, n_theta);
% Y = zeros(n_sec, n_theta);
% Z = zeros(n_sec, n_theta);
% 
% for i_sec = 1:n_sec
%     if i_sec == 1
%         t_vec = path(2,:) - path(1,:);
%     elseif i_sec == n_sec
%         t_vec = path(end,:) - path(end-1,:);
%     else
%         t_vec = path(i_sec+1,:) - path(i_sec-1,:);
%     end
% 
%     L = norm(t_vec);
%     if L < eps
%         if i_sec < n_sec
%             t_vec = path(i_sec+1,:) - path(i_sec,:);
%             L = norm(t_vec);
%         end
%         if L < eps && i_sec > 1
%             t_vec = path(i_sec,:) - path(i_sec-1,:);
%             L = norm(t_vec);
%         end
%         if L < eps
%             t_vec = [1 0 0];
%             L = 1;
%         end
%     end
%     dir = t_vec / L;
% 
%     ref = [0 0 1];
%     if abs(dot(dir, ref)) > 0.9
%         ref = [0 1 0];
%     end
%     u = cross(dir, ref);
%     if norm(u) < eps
%         ref = [1 0 0];
%         u = cross(dir, ref);
%     end
%     u = u / norm(u);
%     w = cross(dir, u);
% 
%     for j = 1:n_theta
%         c = cos(theta(j));
%         s = sin(theta(j));
%         offset = radius * (c*u + s*w);
%         p = path(i_sec,:) + offset;
%         X(i_sec, j) = p(1);
%         Y(i_sec, j) = p(2);
%         Z(i_sec, j) = p(3);
%     end
% end
% 
% h = surf(ax, X, Y, Z, ...
%     'FaceColor', color, ...
%     'EdgeColor', 'none', ...
%     'FaceLighting', 'gouraud', ...
%     'AmbientStrength', 0.22, ...
%     'DiffuseStrength', 0.68, ...
%     'SpecularStrength', 0.88, ...
%     'SpecularExponent', 30, ...
%     'BackFaceLighting', 'reverselit', ...
%     'HandleVisibility', 'off');
% end
