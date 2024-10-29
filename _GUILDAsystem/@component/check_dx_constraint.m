function [dx, con] = check_dx_constraint(obj)
    x = obj.x_equilibrium;
    u = obj.u_equilibrium;
    [dx,con] = obj.get_dx_constraint( 0, x, obj.V_st, obj.I_st, u);
end