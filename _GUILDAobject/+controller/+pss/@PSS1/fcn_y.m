function Vpss = fcn_y(obj, t, x, V, I, u, param, omega0) %#ok
    % 一番最初についてるゲイン
    kpss = param(1);     
    % 位相進み補償器
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    Vpss_min = param(7); 
    Vpss_max = param(8);

    % 周波数
    omega = u;

    % 状態変数
    xiWS = x(1);
    xi1  = x(2);
    xi2  = x(3);        
    
    Vpss = max( min(tn2*(tn1*(kpss*omega - xiWS - xi1)/td1 - xi2)/td2 , Vpss_max), Vpss_min); 
end