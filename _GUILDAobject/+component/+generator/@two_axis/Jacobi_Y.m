function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
    % Cyx
    Cyx = zeros(1,4);
    Cyx(2) = 1;

    % Dyv
    Dyv = zeros(1,2);

    % Dyi
    Dyi = zeros(1,2);

    % Dyu
    Dyu = zeros(1,2);
end