function [Mass, x0] = reset_odeset(obj)
        
    omega0 = obj.para_base.Hz;
    
    n_odeX = 0;
    n_odeU = 0;

    n_Bus    = numel(obj.a_Bus);
    n_Branch  = numel(obj.a_Branch);

    cell_Mass = cell(n_Bus+n_Branch);
    cell_x0   = cell(n_Bus+n_Branch);

    for i = 1:n_Bus
        busi = obj.a_Bus{i};
        [n_odeX,n_odeU, cell_Mass{i}, cell_x0{i}] = busi.reset_odeset(n_odeX, n_odeU, omega0);
    end

    for i = 1:n_Branch
        branchi = obj.a_Branch{i};
        [n_odeX,n_odeU, cell_Mass{n_Bus+i}, cell_x0{n_Bus+i}] = branchi.reset_odeset(n_odeX,n_odeU, omega0);
    end

    Mass = blkdiag(cell_Mass{:});
    x0   = vertcat(cell_x0{:});

    if ~isempty(obj.a_GlobalController)
        gcon = obj.a_GlobalController{1};
        [gcon.cv_Xequilibrium, gcon.cv_Uequilibrium] = gcon.get_equilibrium;
        gcon.set_odefcn(omega0);
    end
end