function Cyx = getJacobiCyx(t,x,V,I,u,param,omega0) %#ok
    ny = 1;
    nx = numel(x);

    Cyx = zeros(ny,nx);
    Cyx(2) = 1;
end