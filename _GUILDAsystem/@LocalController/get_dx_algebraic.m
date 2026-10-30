function [DAEvec, y, y_name] = get_dx_algebraic(obj, t, x, Vi, Ii, obs, DAEvec) 
% Add the DAE residual of the controller (and of its nested controllers) to DAEvec.
%
% Called by Component.get_dx_algebraic. obs.y / obs.x are the outputs and states of the
% observed component: the inputs are read there (iv_obsY / iv_obsX), the outputs of a
% nested controller replace the inputs of the same name, and the other inputs stay at
% the equilibrium.
%
% Outputs:
%
% - `DAEvec` — Updated DAE residual of the network.
% - `y` — Outputs of the controller, which replace the inputs of its parent of the same name.
% - `y_name` — Names of those outputs (sv_y).

    rv_U = obj.rv_Uequilibrium;

    lv_Y = obj.iv_obsY > 0;
    lv_X = obj.iv_obsX > 0;
    rv_U(lv_Y) = obs.y(obj.iv_obsY(lv_Y));
    rv_U(lv_X) = obs.x(obj.iv_obsX(lv_X));

    if obj.l_hasController
        a_LC = obj.a_LocalController{1};

        [DAEvec, y_LC, y_LCname] = get_dx_algebraic(a_LC, t, x, Vi, Ii, obs, DAEvec);    
        
        [lv_U2Y, iv_Y] = ismember(obj.sv_u, y_LCname);
        rv_U(lv_U2Y) = y_LC(iv_Y(lv_U2Y));        
    end

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;        
    
    x_con = x(rv_x);
    u_con = x(rv_u);        
    
    X = obj.f_dx(t, x_con, Vi, Ii, u_con);        
    
    DAEvec([rv_x;rv_u]) = DAEvec([rv_x;rv_u]) + [X; u_con - rv_U];        
    y = obj.f_Y(t, x_con, Vi, Ii, u_con);  
    y_name = obj.sv_y;
    
end
