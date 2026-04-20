function Vpss = fcn_y(obj, t, x, V, u, param, omega0) %#ok
    % 一番最初についてるゲイン
    kpss = param(1);     
    % 位相進み補償器
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    % 周波数
    omega = u;

    % 状態変数
    xiWS = x(1);
    xi1  = x(2);
    xi2  = x(3);    

    vWS = kpss*omega - xiWS;
    v1  = tn1*(vWS-xi1)/td1;       

    vpl  = tn2*(v1-xi2)/td2;
    Vpss = max(min(vpl, Vpss_max), Vpss_min); 
end