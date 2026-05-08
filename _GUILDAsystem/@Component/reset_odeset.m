function [n_odeX, n_odeU, Mass, x0] = reset_odeset(obj, n_odeX, n_odeU, omega0)
    % set index of ode state
    n_odeXi = numel(obj.str_x);
    n_odeUi = numel(obj.str_u);

    obj.iv_odeX = ( 1:n_odeXi )' + n_odeX;
    obj.iv_odeU = ( 1:n_odeUi )' + n_odeU;

    n_odeX  = n_odeX + n_odeXi;
    n_odeU  = n_odeU + n_odeUi;

    % set ode function
    obj.set_odefcn(omega0)

    if ~isempty(obj.a_LocalController)
        cellfun(@(con) con.set_odefcn(omega0), obj.a_LocalController);
    end

    % Mass / x0
    x0   = obj.cv_Xcurrent;
    Mass = obj.rm_odeMass(0,x0,[0;0],zeros(n_odeUi,1));
end