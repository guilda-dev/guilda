function sct = build_index(sct_dae)
% Positions of a run in the DAE vector and what each evaluation reads, from the data of the run.
%
% The DAE vector of the simulation is z = [x; V; I; u; uc]: the variable rows of
% sct_dae.tab_variable in its order (x, Vre/Vim, u, uc), with the bus currents I (Ire, Iim
% of each bus, not in the map) after the voltages. The outputs y and yc are not variables:
% each evaluation computes them into the signal vector s (the rows y, yc of the map). The
% inputs are given by the connection map: res = z_in - (e + S_sig*s + S_var*z), where e
% holds the equilibrium of the inputs without another source. For each connection the
% block of its source is kept (sct_conn), so that set_phase in solve leaves out the
% connections of a tripped source: an input whose main source ("observe" or "local") is
% tripped takes its equilibrium, as an input without a source. Only the data is read: the
% blocks give their rows in the map and their function handles. The mass matrix of each
% block is f_Mass([],[],[],[]); one that is not a constant matrix of its size stops with
% GUILDA:SolverODE:MassNotConstant. Called by solve.
    arguments (Input)
        sct_dae (1,1) struct  % Data of the run (PowerNetwork.build_simulation_data).
    end
    arguments (Output)
        sct (1,1) struct  % Index data of the run (the context ctx of solve).
    end
    tab   = sct_dae.tab_variable;
    tab_c = sct_dae.tab_connection;
    n_bus = numel(sct_dae.sv_bus);

    % Positions in z of the variables, and in s of the signals
    lv_var = tab.Role == "variable";
    n_var  = nnz(lv_var);                     % the variables are the leading rows
    n_xV   = nnz(ismember(tab.Kind, ["x","Vre","Vim"]));
    iv_z   = zeros(height(tab),1);
    iv_z(1:n_xV)       = 1:n_xV;
    iv_z(n_xV+1:n_var) = (n_xV+1:n_var) + 2*n_bus;
    iv_s   = zeros(height(tab),1);
    iv_s(n_var+1:end)  = 1:height(tab)-n_var;
    n_z    = n_var + 2*n_bus;
    n_s    = height(tab) - n_var;
    n_in   = n_var - n_xV;                    % u and uc
    iv_in  = (n_xV + 2*n_bus + 1 : n_z)';
    lv_V   = ismember(tab.Kind, ["Vre","Vim"]);
    iv_V   = iv_z(lv_V);
    iv_I   = n_xV + (1:2*n_bus)';

    sct = struct();
    sct.n_z    = n_z;
    sct.n_s    = n_s;
    sct.n_bus  = n_bus;
    sct.iv_V   = iv_V;
    sct.iv_I   = iv_I;
    sct.iv_in  = iv_in;
    sct.iv_var = iv_z(lv_var);                 % the variable rows, in the order of the map

    % Equilibrium of z and mass matrix
    rv_z0 = zeros(n_z,1);
    rv_z0(sct.iv_var) = sct_dae.rv_equilibrium;
    rv_z0(iv_I) = sct_dae.rv_Iequilibrium;
    c_M = cell(0,2);

    % Components, local controllers and global controllers: the positions in z and s
    sct.c_comp = cell(numel(sct_dae.c_comp),1);
    for j = 1:numel(sct_dae.c_comp)
        b = sct_dae.c_comp{j};
        st = struct("iv_x", iv_z(b.iv_x), "iv_V", iv_V(2*b.i_bus-1 + (0:1)'), ...
                    "iv_u", iv_z(b.iv_u), "iv_s", iv_s(b.iv_y), "l_y", false, ...
                    "f_dx", b.f_dx, "f_I", b.f_I, "f_Y", b.f_Y, "f_JacobiDx", b.f_JacobiDx, ...
                    "f_JacobiI", b.f_JacobiI, "f_JacobiY", b.f_JacobiY, "s_tag", b.s_tag, "iv_lc", b.iv_lc);
        st.f_reconnect = b.f_reconnect;
        c_M(end+1,:) = {st.iv_x, read_mass(b)}; %#ok<AGROW>
        sct.c_comp{j} = st;
    end
    sct.c_lc = cell(numel(sct_dae.c_lc),1);
    for k = 1:numel(sct_dae.c_lc)
        b = sct_dae.c_lc{k};
        sl = struct("iv_x", iv_z(b.iv_x), "iv_V", iv_V(2*b.i_bus-1 + (0:1)'), "iv_u", iv_z(b.iv_u), ...
                    "iv_s", iv_s(b.iv_y), "f_dx", b.f_dx, "f_Y", b.f_Y, ...
                    "f_JacobiDx", b.f_JacobiDx, "f_JacobiY", b.f_JacobiY);
        c_M(end+1,:) = {sl.iv_x, read_mass(b)}; %#ok<AGROW>
        sct.c_lc{k} = sl;
    end
    sct.c_gc = cell(numel(sct_dae.c_gc),1);
    for k = 1:numel(sct_dae.c_gc)
        b = sct_dae.c_gc{k};
        sg = struct("iv_x", iv_z(b.iv_x), "iv_V", iv_V, "iv_u", iv_z(b.iv_u), ...
                    "iv_s", iv_s(b.iv_y), "f_dx", b.f_dx, "f_Y", b.f_Y, ...
                    "f_JacobiDx", b.f_JacobiDx, "f_JacobiY", b.f_JacobiY, "s_tag", b.s_tag);
        c_M(end+1,:) = {sg.iv_x, read_mass(b)}; %#ok<AGROW>
        sct.c_gc{k} = sg;
    end
    sct.rv_z0 = rv_z0;
    M = sparse(n_z, n_z);
    for p = 1:size(c_M,1)
        M(c_M{p,1}, c_M{p,1}) = c_M{p,2}; %#ok<SPRIX>
    end
    sct.rm_M = M;

    % Connections: e (equilibrium), S_sig (signal sources), S_var (state sources)
    iv_tgt = tab_c.TargetIndex - n_xV;
    lv_eq  = tab_c.Kind == "equilibrium";
    rv_in0 = rv_z0(iv_in);
    sct.rv_e0 = zeros(n_in,1);
    sct.rv_e0(iv_tgt(lv_eq)) = rv_in0(iv_tgt(lv_eq));
    lv_sig = ~lv_eq & tab.Role(max(tab_c.SourceIndex,1)) == "signal";
    lv_st  = ~lv_eq & ~lv_sig;
    sct.S_sig0 = sparse(iv_tgt(lv_sig), iv_s(tab_c.SourceIndex(lv_sig)), 1, n_in, n_s);
    sct.S_var0 = sparse(iv_tgt(lv_st), iv_z(tab_c.SourceIndex(lv_st)), 1, n_in, n_z);

    % Source block of each connection (set_phase cuts those of tripped blocks): the block
    % that owns each row of the map, as a component, a local or a global controller
    c_owner = {sct_dae.c_comp, zeros(height(tab),1); sct_dae.c_lc, zeros(height(tab),1); ...
               sct_dae.c_gc, zeros(height(tab),1)};
    for p = 1:size(c_owner,1)
        for k = 1:numel(c_owner{p,1})
            b = c_owner{p,1}{k};
            c_owner{p,2}([b.iv_x; b.iv_u; b.iv_y]) = k;
        end
    end
    lv_conn = ~lv_eq;
    iv_src  = tab_c.SourceIndex(lv_conn);
    sct.sct_conn = struct("iv_in", iv_tgt(lv_conn), ...                   % input (position in iv_in)
                          "lv_sig", lv_sig(lv_conn), ...                  % in S_sig (else S_var)
                          "lv_main", tab_c.Kind(lv_conn) ~= "global", ... % "observe" or "local"
                          "iv_comp", c_owner{1,2}(iv_src), "iv_lc", c_owner{2,2}(iv_src), ...
                          "iv_gc", c_owner{3,2}(iv_src));
    sct.sct_conn.iv_src = zeros(nnz(lv_conn), 1);                        % column in S_sig or S_var
    sct.sct_conn.iv_src(sct.sct_conn.lv_sig)  = iv_s(iv_src(sct.sct_conn.lv_sig));
    sct.sct_conn.iv_src(~sct.sct_conn.lv_sig) = iv_z(iv_src(~sct.sct_conn.lv_sig));

    % The outputs of a component are computed only when a connection reads them
    lv_read = full(any(sct.S_sig0 ~= 0, 1)).';
    for j = 1:numel(sct.c_comp)
        sct.c_comp{j}.l_y = any(lv_read(sct.c_comp{j}.iv_s));
    end
end


function M = read_mass(b)
% The constant mass matrix of a block: f_Mass without t, x, V and u
    arguments (Input)
        b (1,1) struct  % Block of sct_dae (f_Mass, iv_x, s_tag).
    end
    arguments (Output)
        M  % Mass matrix, one row and column per state.
    end
    nx = numel(b.iv_x);
    try
        M = b.f_Mass([],[],[],[]);
    catch ME
        throw_not_constant(b.s_tag, nx, ME.message);
    end
    if ~isequal(size(M),[nx,nx]) && ~(nx == 0 && isempty(M))
        throw_not_constant(b.s_tag, nx, "size " + join(string(size(M)),"x"));
    end
end

function throw_not_constant(s_tag, nx, s_detail)
    error(msg("GUILDA:SolverODE:MassNotConstant", char(s_tag), string(nx), string(nx), s_detail));
end
