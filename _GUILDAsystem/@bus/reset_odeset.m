function [n_odeX, n_odeU, Mass, x0] = reset_odeset(obj, n_odeX, n_odeU, omega0)
    
    % set index of ode state
    obj.iv_odeX = [1;2]+n_odeX;
    n_odeX      = n_odeX+2;

    % reset_odeset for Component Class
    a_Com = obj.a_Component;
    n_Com = numel(a_Com);
    cell_Mass = cell(n_Com,1);
    cell_x0   = cell(n_Com,1);
    for i = 1:n_Com
        [n_odeX,n_odeU, cell_Mass{i}, cell_x0{i}] = a_Com{i}.reset_odeset(n_odeX, n_odeU, omega0);
    end

    Mass = blkdiag(   zeros(2,2), cell_Mass{:} );
    x0   = vertcat( obj.rv_odeX0,   cell_x0{:} );
end