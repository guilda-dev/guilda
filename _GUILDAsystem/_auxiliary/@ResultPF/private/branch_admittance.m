function cm_Y = branch_admittance(sct_branch)
% 2-by-2 admittance matrix of a branch of the snapshot, from its class and its dynamics
% parameters (the formulas of get_admittance_matrix of the branch classes). A class
% without a formula here gives NaN.
    arguments (Input)
        sct_branch struct        % Branch of the snapshot (fields class and tab_parameter).
    end
    arguments (Output)
        cm_Y (2,2) double        % [pu] Admittance matrix.
    end
    para = sct_branch.tab_parameter.dynamics;
    yij  = 1/(para.R + 1j*para.X);
    cij  = 1j*para.C;
    switch string(sct_branch.class)
        case "branch.pi"
            cm_Y = [cij+yij, -yij; -yij, cij+yij];
        case "branch.pi_transformer"
            r    = para.tap * exp(1j*para.phase);
            cm_Y = [(cij+yij)/para.tap^2, -yij/conj(r); -yij/r, cij+yij];
        case "branch.two_winding_transformer"
            ym   = [cij+yij/para.tap^2, -yij/para.tap; -yij/para.tap, yij];
            cm_Y = ym * blkdiag(1, exp(1j*para.phase));
        case "branch.T"
            Y    = 2*yij;
            cm_Y = [Y*(Y+cij), -Y^2; -Y^2, (Y+cij)*Y] / (Y+cij+Y);
        otherwise
            cm_Y = nan(2,2);
    end
end
