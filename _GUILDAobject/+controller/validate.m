% syms t     
% syms xiWS xi1 xi2
% syms Vre Vim     
% syms omega
% 
% kpss      = 20;
% tWS       = 10;
% tn1       = 0.05;
% td1       = 0.02;
% tn2       = 3.00;
% td2       = 5.40;
% Vpss_min  = -10;
% Vpss_max  = 10;
% 
% x = [xiWS; xi1; xi2];
% u = omega;
% % ウォッシュアウトフィルタ
% dx1 = -xiWS + kpss*omega;
% vWS = kpss*omega - xiWS;
% % 位相進み補償器
% dx2 = -xi1 + (1-td1/tn1) * vWS;
% v1  = tn1*(vWS-xi1)/td1;
% % 飽和
% dx3  = -xi2 + (1-td2/tn2) * v1;
% vpl  = tn2*(v1-xi2)/td2;
% Vpss = max(min(vpl, Vpss_max), Vpss_min);
% 
% dx = [dx1; dx2; dx3];
% 
% para = [kpss, tWS, tn1, td1, tn2, td2, Vpss_min, Vpss_max];
% 
% 
% step = heaviside(vpl - Vpss_min) - heaviside(vpl - Vpss_max);
% V    = [Vre; Vim];
% 
% jac = jacobian([dx;vpl], [x;V;u]);
% jac = matlabFunction(jac, Vars={[x;V;u]});
% 
% 
% pss = controller.PSS1("pss");
% pss.set_odefcn(60);
% 
% for i=1:10000
%     x_ = rand([3,1]);
%     V_ = rand([2,1]);
%     u_  = rand([1,1]);
% 
%     JacA  = pss.JacobiA(t,x_,V_,u_);
%     JacB  = pss.JacobiB(t,x_,V_,u_);
%     JacC  = pss.JacobiC(t,x_,V_,u_);
%     JacD  = pss.JacobiD(t,x_,V_,u_);
%     JacBu = pss.JacobiBu(t,x_,V_,u_);
%     JacDu = pss.JacobiDu(t,x_,V_,u_);
% 
%     dif = zeros(1000*4,6);
%     dif(i*(1:4), :) = jac([x_;V_;u_]) - [JacA, JacB, JacBu; JacC, JacD, JacDu];
% end
% 
% all(dif < 1e-14, 1)


ttr      = 0.00;
Vap_max  = 1;
Vap_min  = -1;
kap      = 57.1;
tap      = 0.05;
aex1     = -0.045;
aex2     = 0.0012;
tex      = 0.50;
bex      = 1.21;
kst      = 0.08;
tst      = 1.00;

% リファレンス値
Vref = rand([1,1]);

syms Vtr Vap Vfld Vst Vpss Vabs Vrf

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

x = [Vtr;Vap;Vfld;Vst];
y = x(3);

jac = jacobian([dx;y], [x;Vrf;Vpss;Vabs]);
jac = matlabFunction(jac, Vars={[x;Vrf;Vpss;Vabs]});

avr = controller.avr.AVR_DC1("avr");
avr.set_odefcn(60);

for i=1:10000
    x_ = rand([4,1]);
    V_ = rand([2,1]);
    u_  = rand([3,1]);

    [A, B, C, D] = get_avr_jacobian(x_,u_);

    dif = zeros(1000*5,7);
    dif(i*(1:5), :) = double(jac([x_;V_;u_])) - [A,B;C,D];
end

all(dif < 1e-14, 1)


function [Jx, Ju, Cy, Dy] = get_avr_jacobian(x, u)    
    Vtr  = x(1);
    Vap  = x(2);
    Vfld = x(3);
    Vst  = x(4);

    
    Vref = u(1);
    Vpss = u(2);
    Vabs = u(3);

    
    ttr      = 0.00;
    Vap_max  = 1;
    Vap_min  = -1;
    kap      = 57.1;
    tap      = 0.05;
    aex1     = -0.045;
    aex2     = 0.0012;
    tex      = 0.50;
    bex      = 1.21;
    kst      = 0.08;
    tst      = 1.00;

    
    H_rect = heaviside(Vap - Vap_min) - heaviside(Vap - Vap_max);

    
    Jx = [ -1,          0,                                             0,    0;
          -kap*H_rect, -1*H_rect,                                      0,   -kap*H_rect;
           0,           1, -(aex1 + aex2*(1 + bex*Vfld)*exp(bex*Vfld)),    0;
           0,           0,                                             0,   -1];

    
    Ju = [ 0,           0,           1;
           kap*H_rect,  kap*H_rect,  0;
           0,           0,           0;
           0,           0,           0];

    
    Cy = [0, 0, 1, 0];
    Dy = [0, 0, 0];

end