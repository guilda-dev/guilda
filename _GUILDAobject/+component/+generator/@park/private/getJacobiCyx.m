function Cyx = getJacobiCyx(t,x,V,u,param,omega0) %#ok
    ny = 1;
    nx = numel(x);

    Cyx = zeros(ny,nx);
    Cyx(2) = 1;
end