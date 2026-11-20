function load_data(obj, sct_state)
% Check the state to show (rv_t, cm_Vbus, cm_Icomp) for the network of the diagram and store it.
%
% The currents into the branches at both ends of every sample are computed here and kept
% in sct_state.cm_Ibranch: from the branch matrices of the optional fields c_Ybranch and
% iv_Ybranch (the matrices of each sample), else from the matrices cm_Y of the snapshot.
%
% The scales of the sizes and widths are computed from all samples of the new state
% (update_scale), and so are the flows of the dots and their scale (flow_values); the
% scales of an earlier state are not kept.
%
% An optional field sct_network (a snapshot struct(net, false)) sets the network again
% first (set_data of an edited network; positions are kept by tag, see set_network).
    arguments (Input)
        obj
        sct_state (1,1) struct  % State to show (see the class help), optionally with sct_network.
    end
    if isfield(sct_state, "sct_network")
        obj.set_network(sct_state.sct_network);
    end
    for s_field = ["rv_t", "cm_Vbus", "cm_Icomp"]
        if ~isfield(sct_state, s_field)
            error(msg("GUILDA:GraphNetDiagram:MissingStateField", s_field));
        end
    end
    rv_t = sct_state.rv_t;
    if ~(isnumeric(rv_t) && isreal(rv_t) && isvector(rv_t) && all(isfinite(rv_t)))
        error(msg("GUILDA:GraphNetDiagram:StateSize", "rv_t", "a finite real 1xn_t vector", size_text(rv_t)));
    end
    n_t = numel(rv_t);
    if isempty(sct_state.cm_Icomp) && obj.n_component == 0
        sct_state.cm_Icomp = zeros(0, n_t);
    end
    if ~isnumeric(sct_state.cm_Vbus) || ~isequal(size(sct_state.cm_Vbus), [obj.n_bus, n_t])
        error(msg("GUILDA:GraphNetDiagram:StateSize", "cm_Vbus", obj.n_bus + "x" + n_t, size_text(sct_state.cm_Vbus)));
    end
    if ~isnumeric(sct_state.cm_Icomp) || ~isequal(size(sct_state.cm_Icomp), [obj.n_component, n_t])
        error(msg("GUILDA:GraphNetDiagram:StateSize", "cm_Icomp", obj.n_component + "x" + n_t, size_text(sct_state.cm_Icomp)));
    end
    cm_V = double(sct_state.cm_Vbus);
    if isfield(sct_state, "c_Ybranch")
        % Branch matrices of each sample: page k of c_Ybranch{iv_Ybranch(t)} for branch k
        iv_Y = reshape(sct_state.iv_Ybranch, 1, []);
        c_Y  = sct_state.c_Ybranch;
        if numel(iv_Y) ~= n_t || ~all(ismember(iv_Y, 1:numel(c_Y)))
            error(msg("GUILDA:GraphNetDiagram:StateSize", "iv_Ybranch", n_t + " positions in c_Ybranch", size_text(iv_Y)));
        end
        cm_Ibr = complex(zeros(2*obj.n_branch, n_t));
        for i_Y = unique(iv_Y)
            cm_Yi = c_Y{i_Y};
            if ~isequal(size(cm_Yi, [1 2 3]), [2, 2, obj.n_branch])
                error(msg("GUILDA:GraphNetDiagram:StateSize", "c_Ybranch{" + i_Y + "}", "2x2x" + obj.n_branch, size_text(cm_Yi)));
            end
            lv_t = iv_Y == i_Y;
            for k = 1:obj.n_branch
                cm_Ibr(2*k-1:2*k, lv_t) = cm_Yi(:, :, k) * cm_V(obj.im_edge(:, k), lv_t);
            end
        end
    else
        cm_Ibr = full(obj.cm_Vbus2Ibranch * cm_V);
    end
    obj.sct_state = struct("rv_t", reshape(double(rv_t), 1, []), ...
        "cm_Vbus", cm_V, "cm_Icomp", double(sct_state.cm_Icomp), "cm_Ibranch", cm_Ibr);
    obj.rv_t   = obj.sct_state.rv_t;
    obj.i_time = 1;
    obj.load_sample_label(sct_state);
    obj.update_scale();                % the scales of the sizes belong to the state
    obj.update_color_scale();          % and the automatic color limits
    obj.flow_values();                 % and the flows with their scale
end


function s = size_text(x)
% Size of x as text, e.g. "3x1".
    arguments (Input)
        x  % Any value.
    end
    arguments (Output)
        s (1,1) string  % Its size.
    end
    s = join(string(size(x)), "x");
end
