function dx = fcn_dx(obj, t, x, V, u, param, omega0) %#ok
                
    % リファレンス値
    Vref = u(1);
    % 増幅器
    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4);    
    % 励磁器
    aex1 = param(6);
    aex2 = param(7);    
    bex  = param(9);    

    Vtr  = x(1);
    Vap  = x(2);
    Vfld = x(3);
    Vst  = x(4);

    % 入力
    Vabs = abs([1,1j]*V);        
    Vpss = u(2);
    % 計測用変圧器
    dx1 = -Vtr + Vabs;
    % コンパレータ
    Vcom = Vref + Vpss - Vtr - Vst;
    % 増幅器
    dx2 = ( -Vap + kap*Vcom )*( heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max) );
    % 励磁器
    dx3 = -( aex1 + aex2 * exp(bex*Vfld) ) * Vfld + Vap;
    % 安定化回路
    dx4 = -Vst;    

    dx = [dx1;dx2;dx3;dx4];
    
end