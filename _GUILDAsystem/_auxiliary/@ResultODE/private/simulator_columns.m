function [iv_sim, c_index] = simulator_columns(net, tab)
% iv_sim(m): column of the simulator state (iv_odeX / iv_odeU set by
% SolverODE.initialize_index) that holds the variable tab(m,:). Walks the network in
% the order of get_variable_map and checks the result against the labels of tab.
% c_index{i}: columns of tab for the view odeResults (bus i).
    a_bus = net.a_Bus;
    a_gc  = net.a_GlobalController;
    n_bus = numel(a_bus);

    c_x = cell(0,1);  c_lx = cell(0,1);     % states: simulator indices and labels
    c_u = cell(0,1);  c_lu = cell(0,1);     % inputs
    c_comp = cell(n_bus,1);                 % per bus, per component: [n_x, n_u] of the component
    for i = 1:n_bus
        a_comp = a_bus{i}.a_Component;
        c_comp{i} = zeros(numel(a_comp), 2);
        for j = 1:numel(a_comp)
            comp  = a_comp{j};
            a_obj = [{comp}; all_controllers(comp)];
            for k = 1:numel(a_obj)
                c_x{end+1,1}  = reshape(a_obj{k}.iv_odeX, [], 1); %#ok<AGROW>
                c_lx{end+1,1} = label(a_obj{k}, a_obj{k}.sv_x);   %#ok<AGROW>
            end
            c_u{end+1,1}  = reshape(comp.iv_odeU, [], 1); %#ok<AGROW>
            c_lu{end+1,1} = label(comp, comp.sv_u);       %#ok<AGROW>
            c_comp{i}(j,:) = [numel(comp.sv_x), numel(comp.sv_u)];
        end
    end
    c_gx = tools.cellfun(@(g) reshape(g.iv_odeX, [], 1), a_gc);
    c_gl = tools.cellfun(@(g) label(g, g.sv_x), a_gc);
    c_V  = tools.cellfun(@(b) reshape(b.iv_odeX, [], 1), a_bus);
    c_lV = tools.cellfun(@(b) label(b, ["Vre";"Vim"]), a_bus);

    iv_sim   = vertcat(zeros(0,1), c_x{:}, c_gx{:}, c_V{:}, c_u{:});
    sv_label = vertcat(strings(0,1), c_lx{:}, c_gl{:}, c_lV{:}, c_lu{:});
    if numel(iv_sim) ~= height(tab) || ~isequal(sv_label, string(tab.Label))
        error(msg("GUILDA:ResultODE:VariableMap"))
    end

    % columns of the view: the component's own states (not its controllers) and inputs
    [~, c_idxBus] = net.get_variable_map();
    c_index = cell(n_bus,1);
    iv_u0 = find(tab.Kind == "u", 1) - 1;
    if isempty(iv_u0)
        iv_u0 = height(tab);
    end
    n_u = 0;
    for i = 1:n_bus
        a_comp = a_bus{i}.a_Component;
        iv_bus = c_idxBus{i};
        iv_bus = iv_bus(iv_bus <= height(tab));   % its rows x, Vre, Vim, u
        iv_bx  = iv_bus(tab.Kind(iv_bus) == "x");
        s = struct();
        s.iv_V = iv_bus(tab.Kind(iv_bus) == "Vre" | tab.Kind(iv_bus) == "Vim");
        s.c_x  = cell(1, numel(a_comp));
        s.c_u  = cell(1, numel(a_comp));
        n_x = 0;
        for j = 1:numel(a_comp)
            s.c_x{j} = iv_bx(n_x + (1:c_comp{i}(j,1)));
            s.c_u{j} = iv_u0 + n_u + (1:c_comp{i}(j,2))';
            n_x = n_x + numel(a_comp{j}.sv_x) + sum(cellfun(@(c) numel(c.sv_x), all_controllers(a_comp{j})));
            n_u = n_u + c_comp{i}(j,2);
        end
        c_index{i} = s;
    end
end
