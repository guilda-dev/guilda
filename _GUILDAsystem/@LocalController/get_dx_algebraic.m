function [DAEvec, y] = get_dx_algebraic(obj, t, x, Vi, Ii, obs, DAEvec) 
% Add the DAE residual of the controller (and of its nested controllers) to DAEvec.
%
% Called by Component.get_dx_algebraic. obs.y / obs.x are the outputs and states of the
% observed component: the inputs are read there (iv_obsY / iv_obsX), the outputs of a
% nested controller replace the inputs of the same name, and the other inputs stay at
% the equilibrium.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        t      (1,1) double  % [s] Time.
        x      (:,1) double  % Variables of the network DAE (states, inputs, bus voltages and currents).
        Vi     (2,1) double  % [pu] Voltage of the bus of the observed component [real; imag].
        Ii     (2,1) double  % [pu] Current of the bus of the observed component [real; imag].
        obs    (1,1) struct  % Outputs (obs.y) and states (obs.x) of the observed component.
        DAEvec (:,1) double  % DAE residual of the network so far.
    end
    arguments (Output)
        DAEvec (:,1) double  % Updated DAE residual of the network.
        y      (:,1) double  % Outputs of the controller, which drive the inputs of its parent of the same name.
    end

    % A controller attached after its component was brought up to date (see
    % Component.get_dx_algebraic)
    if obj.s_odefcn ~= "updated"
        obj.check_edit();
    end

    rv_U = obj.rv_Uequilibrium;

    lv_Y = obj.iv_obsY > 0;
    lv_X = obj.iv_obsX > 0;
    rv_U(lv_Y) = obs.y(obj.iv_obsY(lv_Y));
    rv_U(lv_X) = obs.x(obj.iv_obsX(lv_X));

    if obj.l_hasController
        % y_LC: the outputs of the nested controllers, stacked in order (iv_odeYtoU)
        a_LC = obj.a_LocalController;
        [DAEvec, y_LC] = get_dx_algebraic(a_LC{1}, t, x, Vi, Ii, obs, DAEvec);
        for k = 2:numel(a_LC)
            [DAEvec, y_k] = get_dx_algebraic(a_LC{k}, t, x, Vi, Ii, obs, DAEvec);
            y_LC = [y_LC; y_k]; %#ok<AGROW>
        end
        
        lv_U2Y = obj.lv_odeUfromLC;
        rv_U(lv_U2Y) = y_LC(obj.iv_odeYtoU(lv_U2Y));        
    end

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;        
    
    x_con = x(rv_x);
    u_con = x(rv_u);        
    
    X = obj.f_dx(t, x_con, Vi, Ii, u_con);        
    
    DAEvec([rv_x;rv_u]) = DAEvec([rv_x;rv_u]) + [X; u_con - rv_U];        
    y = obj.f_Y(t, x_con, Vi, Ii, u_con);  
    
end
