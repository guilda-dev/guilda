% V = 0.54 + 1j*0.19;
% I = 0.12 + 1j*0.32;
% 
% 
% load1 = component.load.impedance();
% load2 = component.load.power();
% load3 = component.load.current();
% 
% load1.set_equilibrium(V, I);
% load2.set_equilibrium(V, I);
% load3.set_equilibrium(V, I);
% 
% load1.x_equilibrium;
% load1.u_equilibrium;
% 
% load2.x_equilibrium;
% load2.u_equilibrium;
% 
% load3.x_equilibrium;
% load3.u_equilibrium;
% 
% 
% load1.get_xequilibrium(V, I);
% load2.get_xequilibrium(V, I);
% load3.get_xequilibrium(V, I);
% 
% u = load1.get_uequilibrium(V, I);
% load1.dynamics(-1, V, u.z)




% 定電力負荷のヤコビアンがきちんと実装できているかの確認
c1 = component.load.power;
c1.set_odefcn;

syms Vre Vim P Q

I = (P-1j*Q)/(Vre-1j*Vim);
j = jacobian([real(I);imag(I)], [Vre;Vim]);

t = [];
x = [];
V = rand([2,1], "double");
u = rand([2,1], "double");


for it = 1:1000
    t = [];
    x = [];
    V = rand([2,1], "double");
    u = rand([2,1], "double");

    dif = zeros(2*1000,2);
    dif(it*[1,2],:) = c1.JacobiD(t, x, V, u) - double( subs(j, [P;Q;Vre;Vim], [u;V]) );
end

all(dif < 1e-14) % ← trueなのでOK
