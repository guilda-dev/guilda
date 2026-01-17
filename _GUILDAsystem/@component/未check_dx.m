function [dx,y] = check_dx(obj)
    x = obj.x_equilibrium;
    u = obj.u_equilibrium;
    y = obj.y_equilibrium;
    V = obj.equilibrium(1:2);
    I = obj.equilibrium(3:4);
    
    dx = obj.fcn_diff(0,x,V,I,u);
    y  = obj.fcn_output(0,x,V,I,u) - [y;V;I];
end