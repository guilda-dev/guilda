function [Cyx, Dyv, Dyi, Dyu] = Jacobi_Y_num(obj,r_t,rv_x,rv_V,rv_I,rv_u,rr_param,r_omega0)

    fcn     = @(x,v,i,u) obj.fcn_Y(r_t, x, v, i, u, rr_param, r_omega0);
    
    % make variable
    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);
    
    % make function
    d = 1e-5;
    e = @(i,n) d/2 * ((1:n)==i).';
    
    % get linearized matrix numerically
    jacobi = zeros(ny, nx+2+2+nu);
    for i = 1:nx
        jacobi(:,i)      = fcn(rv_x+e(i,nx), rv_V       , rv_I       , rv_u        ) ...
                         - fcn(rv_x-e(i,nx), rv_V       , rv_I       , rv_u        );
    end
    for i = 1:2
        jacobi(:,nx+i)   = fcn(rv_x        , rv_V+e(i,2), rv_I       , rv_u        ) ...
                         - fcn(rv_x        , rv_V-e(i,2), rv_I       , rv_u        );
    end  
    for i = 1:2
        jacobi(:,nx+2+i) = fcn(rv_x        , rv_V       , rv_I+e(i,2), rv_u        ) ...
                         - fcn(rv_x        , rv_V       , rv_I-e(i,2), rv_u        );
    end
    for i = 1:nu
        jacobi(:,nx+4+i) = fcn(rv_x        , rv_V       , rv_I       , rv_u+e(i,nu)) ...
                         - fcn(rv_x        , rv_V       , rv_I       , rv_u-e(i,nu));
    end
    jacobi = jacobi/d;
    
    Cyx = jacobi(:,(1:nx)     );
    Dyv = jacobi(:,(1: 2)+nx  );
    Dyi = jacobi(:,(1: 2)+nx+2);
    Dyu = jacobi(:,(1:nu)+nx+4);
end
