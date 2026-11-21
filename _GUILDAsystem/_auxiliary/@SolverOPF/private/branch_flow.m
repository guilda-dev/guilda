function rm_flow = branch_flow(row, rv_V, rv_Varg, s_method)
% Flows at the two ends of one branch, from the voltages of its end buses.
%
% Each column is one end (1: bus From, 2: bus To) and holds the flow from the branch into
% that bus. "AC OPF": rows P, Q, Ireal, Iimag, from I = -Y*V (Y the 2x2 admittance
% matrix of the branch, with its tap and phase) and S = V*conj(I). "DC OPF": one row P,
% with |V| = 1, no losses and the MATPOWER flow b*(θi - θj - phase) from bus i,
% b = 1/(X*tap) (tap ratio and phase shift at the From end). The voltages are numbers
% (the solution, in solve) or optimization expressions (the problem, in build_branch);
% the result is of the same kind.
    arguments (Input)
        row        table         % Row of the branch table (From, To, Y, X, tap, phase, ...).
        rv_V       (1,2)         % [pu] V of the end buses (From, To); not read in "DC OPF".
        rv_Varg    (1,2)         % [rad] Varg of the end buses (From, To).
        s_method   (1,1) string  % "DC OPF" or "AC OPF".
    end
    arguments (Output)
        rm_flow  % 4 x 2 ("AC OPF") or 1 x 2 ("DC OPF") flows into the end buses.
    end
    if s_method == "DC OPF"
        b       = 1/(row.X*row.tap);
        rm_flow = [b*(rv_Varg(2) - rv_Varg(1) + row.phase), b*(rv_Varg(1) - rv_Varg(2) - row.phase)];
        return
    end
    % The direction into the bus is positive, hence the minus sign.
    rm_Y = -reshape(row.Y, 2, 2);
    G    = real(rm_Y);
    B    = imag(rm_Y);
    Vre  = rv_V .* cos(rv_Varg);
    Vim  = rv_V .* sin(rv_Varg);
    c_end = cell(1, 2);
    for k = 1:2
        Ire = G(k,1)*Vre(1) - B(k,1)*Vim(1) + G(k,2)*Vre(2) - B(k,2)*Vim(2);
        Iim = G(k,1)*Vim(1) + B(k,1)*Vre(1) + G(k,2)*Vim(2) + B(k,2)*Vre(2);
        c_end{k} = [Vre(k)*Ire + Vim(k)*Iim; Vim(k)*Ire - Vre(k)*Iim; Ire; Iim];
    end
    rm_flow = [c_end{:}];
end
