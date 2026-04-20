function [dx,I,y] = dynamics( ~, V, u, ~, ~)
    dx = zeros(0, 1);

    Gload = u(1)+1j*u(2);
    Bload = u(2);
    Yload = Gload+1j*Bload;
    
    I = Yload*V;
    y = [];
end