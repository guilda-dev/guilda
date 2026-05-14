function dx = fcn_dx(obj, t, x, V, I, u, param, omega0) %#ok   
        
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
    
    % ウォッシュアウトフィルタ    
    vWS = kpss*omega - xiWS;
    % 位相進み補償器    
    v1  = tn1*(vWS-xi1)/td1;    

    dx = [-xiWS + kpss*omega; -xi1 + (1-td1/tn1) * vWS; -xi2 + (1-td2/tn2) * v1];
    
end