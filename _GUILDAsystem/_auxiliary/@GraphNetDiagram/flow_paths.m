function flow_paths(obj)
% Prepare the paths of the flow dots from the drawn paths of the branches and links (2D).
%
% For the branches (first) and the links (second), the paths (sct_plt.EdgePath and
% CompPath, with their heights) are joined into one polyline, a gap of d0 between two
% elements, so that the position of every dot is found by one interpolation. The length
% along a path is measured in 3D, so a dot keeps its speed along a sloping line. Each
% element has its candidate dots k = 0, 1, ... with k*Delta up to its length (Delta =
% 0.25*d0, the spacing of the dots). Called by create_scene and whenever the heights
% change; the phases of the dots stay, so the dots do not jump. In 3D there is nothing.
    arguments (Input)
        obj
    end
    obj.sct_flowPath = struct.empty;
    if validate(obj) || ~isfield(obj.sct_plt, "FlowBranch") || ~any(isgraphics(obj.sct_plt.FlowBranch))
        return
    end
    d0      = obj.sct_plt.D0;
    r_delta = 0.25*d0;
    c_set   = {obj.sct_plt.EdgePath, obj.sct_plt.CompPath};
    for j = 1:2
        c_path = c_set{j};
        n      = numel(c_path);
        c_p    = cell(n, 1);
        rv_len = zeros(n, 1);
        for i = 1:n
            rm_p = c_path{i};
            rm_p = rm_p([true; any(diff(rm_p, 1, 1) ~= 0, 2)], :);   % no segment of length 0
            c_p{i}    = rm_p;
            rv_len(i) = sum(vecnorm(diff(rm_p, 1, 1), 2, 2));
        end
        rm_p   = vertcat(c_p{:}, zeros(0, 3));
        rv_seg = vecnorm(diff(rm_p, 1, 1), 2, 2);
        iv_n   = cellfun(@(p) size(p, 1), c_p);
        iv_last = cumsum(iv_n);
        rv_seg(iv_last(1:end-1)) = d0;                               % gap between two elements
        rv_cum = [0; cumsum(rv_seg)];
        rv_g   = rv_cum(iv_last - iv_n + 1);                          % start of each element
        rm_t   = diff(rm_p, 1, 1) ./ max(rv_seg, eps);                % unit tangent of each segment
        iv_k   = floor(rv_len / r_delta) + 1;                         % candidate dots of each element
        iv_k(rv_len <= 0) = 0;
        iv_e   = repelem((1:n)', iv_k);
        rv_k   = zeros(numel(iv_e), 1);
        if ~isempty(iv_e)
            iv_start = cumsum([1; iv_k(1:end-1)]);
            rv_k = (1:numel(iv_e))' - repelem(iv_start, iv_k);
        end
        sct = struct("rm_p", rm_p, "rv_cum", rv_cum, "rm_t", rm_t, "rv_g", rv_g, ...
                     "rv_len", rv_len, "iv_e", iv_e, "rv_k", rv_k);
        if j == 1
            obj.sct_flowPath = sct;
        else
            obj.sct_flowPath(2) = sct;
        end
    end
end
