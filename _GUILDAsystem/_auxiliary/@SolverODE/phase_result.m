function sct_out = phase_result(net, ph, sct_sol, Ymat)
% Trajectory of one phase (t, x, bus currents i) for ResultODE; the states of the
% tripped units are NaN.
    arguments (Input)
        net      % Network of the run.
        ph       % Data of the phase (an element of the output of Scenario.compile).
        sct_sol  % Solution of the phase (fields Time and Solution, full state vector).
        Ymat     % [pu] Real admittance matrix of the phase (I = Y*V).
    end
    arguments (Output)
        sct_out  % Trajectory of the phase (fields t, x, i).
    end
    a_bus = net.a_Bus;
    a_cmp = cellfun(@(bi) bi.a_Component, a_bus, 'UniformOutput', false);
    a_cmp = vertcat(a_cmp{:});

    % Tripped units by tag (getStateTags also lists local controllers, so its
    % positions do not match a_cmp); a tripped global controller is marked too
    a_unit   = [a_cmp; net.a_GlobalController];
    lv_Ctagi = ismember(string(a_unit), ph.sv_trip);

    B_sti = cell2mat( cellfun(@(bi) bi.iv_odeX, a_bus, 'UniformOutput', false) );
    C_sti = cell2mat( cellfun(@(ci) ci.iv_odeX, a_unit(lv_Ctagi), 'UniformOutput', false) );

    Time = sct_sol.Time;
    xsol = sct_sol.Solution;

    if any(lv_Ctagi)
        xsol(:, C_sti) = NaN;
    end

    Vsol = xsol(:, B_sti);
    Isol = Ymat * Vsol.';

    sct_out = struct('t', Time, 'x', xsol, 'i', Isol.');
end
