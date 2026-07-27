function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok
                
    % リファレンス値
    Vref = u(1);    
    
    kap  = param(4);    

    Vtr  = x(1);
    Vap  = x(2);    
    Vst  = x(3);

    % 入力
    Vabs = abs([1,1j]*V);        
    Vpss = u(2);
    % 計測用変圧器
    dx1 = -Vtr + Vabs;
    % コンパレータ
    Vcom = Vref + Vpss - Vtr - Vst;    
    % 増幅器    
    dx2 = -Vap + kap*Vcom;
    
    % 安定化回路
    % dx3 = -Vst + kst * Vap;    
    dx3 = -Vst;    

    dx = [dx1;dx2;dx3];
    
end