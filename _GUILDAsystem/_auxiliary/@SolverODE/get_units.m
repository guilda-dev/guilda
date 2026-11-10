function [c_unit, c_gc] = get_units(net)
% What getODEFunction reads for each component and global controller, fixed during a run
%
% The routing of the outputs of each global controller is resolved here, by name: an output
% goes to every local controller of the unit (nested ones included) with an input of that
% name, otherwise to the input of the unit. When it differs from sv_route of the
% controller (a local controller was added, removed or replaced), an INFO message says
% which outputs go elsewhere now and sv_route is updated. An output that has no input to
% drive stops with GUILDA:SolverODE:GconNoTarget. Called by solve after initialize_index.
    arguments (Input)
        net  % Network of the run.
    end
    arguments (Output)
        c_unit  % One struct per component (fields ue, idx_X, idx_U, idx_V, idx_Y, l_y, comp).
        c_gc    % One struct per global controller (fields gc, iv_unit, iv_y, iv_x, lv_y, lv_x, iv_tgt, iv_src).
    end
    c_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);
    c_comp = vertcat(cell(0,1), c_comp{:});
    a_gc   = net.a_GlobalController;

    % The outputs y of the components that a local controller or a global controller
    % reads, stacked (idx_Y: positions in that vector)
    lv_y = cellfun(@(c) c.l_hasController, c_comp);
    for k = 1:numel(a_gc)
        n_u = numel(a_gc{k}.sv_u);
        for idx = 1:numel(a_gc{k}.controlledUnits)
            if any(a_gc{k}.iv_obsY((idx-1)*n_u + (1:n_u)) > 0)
                lv_y = lv_y | cellfun(@(c) c == a_gc{k}.controlledUnits{idx}, c_comp);
            end
        end
    end
    lv_y = lv_y & cellfun(@(c) ~isempty(c.sv_y), c_comp);

    c_unit = cell(size(c_comp));
    n_y = 0;
    for i = 1:numel(c_comp)
        cj = c_comp{i};
        idx_Y = zeros(0,1);
        if lv_y(i)
            idx_Y = n_y + (1:numel(cj.sv_y))';
            n_y = n_y + numel(cj.sv_y);
        end
        c_unit{i} = struct("ue", cj.rv_Uequilibrium, "idx_X", cj.iv_odeX, "idx_U", cj.iv_odeU, ...
                           "idx_V", cj.a_Bus.iv_odeX, "idx_Y", idx_Y, "l_y", lv_y(i));
        c_unit{i}.comp = cj;           % not an argument of struct: Component overloads it
    end

    % Global controllers: where each input is read (iv_y: position in the stacked outputs,
    % iv_x: position in the simulation vector) and where each output goes (iv_tgt: the
    % driven input in the simulation vector, iv_src: the row of the output)
    c_gc = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        gc = a_gc{k};
        a_unit = gc.controlledUnits;
        n_u = numel(gc.sv_u);
        n_o = numel(gc.sv_y);
        iv_unit = zeros(numel(a_unit)*n_u, 1);
        iv_y    = zeros(numel(a_unit)*n_u, 1);
        iv_x    = zeros(numel(a_unit)*n_u, 1);
        iv_tgt  = zeros(0,1);
        iv_src  = zeros(0,1);
        sv_route = strings(0,1);
        for idx = 1:numel(a_unit)
            unit = a_unit{idx};
            i_unit = find(cellfun(@(c) c == unit, c_comp), 1);
            iv_k = (idx-1)*n_u + (1:n_u)';
            iv_unit(iv_k) = i_unit;
            lv_Y = gc.iv_obsY(iv_k) > 0;
            lv_X = gc.iv_obsX(iv_k) > 0;
            iv_y(iv_k(lv_Y)) = c_unit{i_unit}.idx_Y(gc.iv_obsY(iv_k(lv_Y)));
            iv_x(iv_k(lv_X)) = unit.iv_odeX(gc.iv_obsX(iv_k(lv_X)));

            c_LC = controllers_depth_first(unit);
            for m = 1:n_o
                s_out = gc.sv_y(m);
                i_src = (idx-1)*n_o + m;
                lv_LC = cellfun(@(c) any(c.sv_u == s_out), c_LC);
                if any(lv_LC)
                    iv_in = cellfun(@(c) c.iv_odeU(find(c.sv_u == s_out, 1)), c_LC(lv_LC));
                    s_to  = "to the input of " + join(cellfun(@(c) string(c.s_tag), c_LC(lv_LC)), ", ");
                elseif any(unit.sv_u == s_out)
                    iv_in = unit.iv_odeU(find(unit.sv_u == s_out, 1));
                    s_to  = "directly to the component input";
                else
                    error(msg("GUILDA:SolverODE:GconNoTarget", char(gc.s_tag), char(s_out), char(unit.s_tag)))
                end
                iv_tgt = [iv_tgt; reshape(iv_in, [], 1)];                     %#ok<AGROW>
                iv_src = [iv_src; repmat(i_src, numel(iv_in), 1)];             %#ok<AGROW>
                sv_route = [sv_route; s_out + " of " + unit.s_tag + " goes " + s_to]; %#ok<AGROW>
            end
        end
        % The same lines as add_global_controller: report the ones that changed
        if ~isequal(sv_route, gc.sv_route)
            lv_new = ~ismember(sv_route, gc.sv_route);
            show_msg("info", "GUILDA:SolverODE:GconRouteChanged", gc.s_tag, ...
                     join(replace(sv_route(lv_new), " goes ", " now goes "), "; "))
            gc.sv_route = sv_route;
        end
        c_gc{k} = struct("iv_unit", iv_unit, "iv_y", iv_y, "iv_x", iv_x, "lv_y", iv_y > 0, "lv_x", iv_x > 0, ...
                         "iv_tgt", iv_tgt, "iv_src", iv_src);
        c_gc{k}.gc = gc;
    end
end
