function [rv_x0, rm_Mass, TC] = getXM(OBJs, rv_x0, rm_Mass, TC)

    for no = 1:numel(OBJs)
        OBJ = OBJs{no};
        rx_idx = [OBJ.iv_odeX; OBJ.iv_odeU];
        nu_idx = numel(OBJ.iv_odeU);

        if isa(OBJ, 'Component')
            OBJ.l_isConnect = ~ismember(OBJ.s_tag, TC);
        end
        rv_u0 = OBJ.rv_Uequilibrium;
        if ~isempty(OBJ.rv_Uoffset)     % empty without an input (see Scenario.compile)
            rv_u0 = rv_u0 + OBJ.rv_Uoffset(0);
        end
        rv_x0 = [rv_x0; OBJ.rv_Xequilibrium + OBJ.rv_Xoffset; rv_u0]; %#ok

        rm_Mass(rx_idx, rx_idx) = blkdiag(tools.read_mass(OBJ), zeros(nu_idx, nu_idx));

        if ~isempty(OBJ.a_LocalController)
            [rv_x0, rm_Mass, TC] = getXM(OBJ.a_LocalController, rv_x0, rm_Mass, TC);
        end
    end
end
