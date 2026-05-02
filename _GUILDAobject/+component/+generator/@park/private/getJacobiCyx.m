function JacobiCyx = getJacobiCyx(t,x,V,u,param,omega0) %#ok
    ny = 1;
    nx = numel(x);

    JacobiCyx = zeros(ny,nx);
    JacobiCyx(2) = 1;
end