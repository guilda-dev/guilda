function Div = getJacobiDiv(t, x, V, I, u, param) %#ok    

    R = u(1);
    X = u(2);

    RX = R^2 + X^2;

    Div = [ -R, -X; 
             X, -R] / RX;
end