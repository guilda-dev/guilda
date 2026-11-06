function initialize_index(net)
% Method for assigning state variable numbers to each device and bus.
% Execute this before performing analysis using the ODE solver. Stops with
% GUILDA:SolverODE:Stale when a stale tag it reads is not empty: powerflow and odefcn of
% the network, equilibrium and odefcn of each component, local and global controller.
    arguments (Input)
        net  % Network of the run.
    end

    % Global controllers must not read the indices of a component outside the network.
    for k = 1:numel(net.a_GlobalController)
        gcon = net.a_GlobalController{k};
        for idx = 1:numel(gcon.controlledUnits)
            unit = gcon.controlledUnits{idx};
            if isempty(unit.a_Bus) || ~isequal(unit.a_Bus.a_PowerNetwork, net)
                error(msg("GUILDA:SolverODE:ForeignControlledUnit", char(gcon.s_tag), char(unit.s_tag), char(net.s_tag)))
            end
        end
    end

    a_bus = net.a_Bus;

    idx_TGT = 0;
    sv = [net.sct_stale.powerflow; net.sct_stale.odefcn];   % messages of the stale tags

    for i=1:numel(a_bus)
        a_comp = a_bus{i}.a_Component;

        for j=1:numel(a_comp)
            % The component, then its local controllers depth first (get_variable_map)
            set_idx(a_comp{j});
            set_idx_controllers(a_comp{j});
        end
    end

    % Global controllers: states after the components, in the order of a_GlobalController.
    % Their inputs are states of the controlled units and their outputs are inputs of them.
    a_gcon = net.a_GlobalController;
    for k = 1:numel(a_gcon)
        gcon = a_gcon{k};
        sv   = [sv; gcon.sct_stale.equilibrium; gcon.sct_stale.odefcn]; %#ok<AGROW>
        nxgc = length(gcon.sv_x);
        gcon.iv_odeX = idx_TGT + (1:nxgc)';
        idx_TGT = idx_TGT + nxgc;

        nConUnit = gcon.controlledUnits;
        gcon.iv_odeU = zeros(numel(nConUnit),1);
        gcon.iv_odeY = zeros(numel(nConUnit),1);
        for idx = 1:numel(nConUnit)
            gcon.iv_odeU(idx) = nConUnit{idx}.iv_odeX( nConUnit{idx}.sv_x==gcon.sv_u );
            gcon.iv_odeY(idx) = nConUnit{idx}.iv_odeU( nConUnit{idx}.sv_u==gcon.sv_y );
        end
    end

    if ~isempty(sv)
        sv = unique(sv, "stable");
        s_reason = join(sv(1:min(end,3)), "; ");
        if numel(sv) > 3
            s_reason = s_reason + "; ...";
        end
        error(msg("GUILDA:SolverODE:Stale", char(net.s_tag), char(s_reason)))
    end

    for i=1:numel(a_bus)
        a_bus{i}.iv_odeX = idx_TGT + (1:2).';
        idx_TGT = idx_TGT + 2;
        a_bus{i}.iv_odeI = idx_TGT + (1:2).';
        idx_TGT = idx_TGT + 2;
    end

    function set_idx_controllers(parent)
        % Each controller under parent and the controllers nested in it, depth first
        for k_con = 1:numel(parent.a_LocalController)
            con = parent.a_LocalController{k_con};
            set_idx(con);
            % iv_odeY(k): the input of the parent driven by the output sv_y(k), by name
            [~, iv_y] = ismember(con.sv_y, parent.sv_u);
            con.iv_odeY = parent.iv_odeU(iv_y);
            set_idx_controllers(con);
        end
    end

    function set_idx(OBJ)
        % The inputs driven by the outputs of the controllers under OBJ, by name
        % (their outputs stacked in the order of a_LocalController; disjoint names)
        if OBJ.l_hasController
            c_y = cellfun(@(c) reshape(string(c.sv_y),[],1), OBJ.a_LocalController, 'UniformOutput', false);
            [OBJ.lv_odeUfromLC, OBJ.iv_odeYtoU] = ismember(OBJ.sv_u, vertcat(strings(0,1), c_y{:}));
        end

        sv = [sv; OBJ.sct_stale.equilibrium; OBJ.sct_stale.odefcn];

        nx = length(OBJ.sv_x);
        nu = length(OBJ.sv_u);

        OBJ.iv_odeX = idx_TGT + (1:nx)';
        idx_TGT = idx_TGT + nx;

        OBJ.iv_odeU = idx_TGT + (1:nu)';
        idx_TGT = idx_TGT + nu;
    end

end
