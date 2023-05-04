origin = net.a_bus{1}.component;

nx = origin.get_nx;
nu = origin.get_nu;

t = 0;
V = origin.V_equilibrium;
I = origin.I_equilibrium;
xeq = origin.x_equilibrium
ref = origin.alpha_st


c = component.generator.one_axis(origin.parameter);
func = @(var) fx(c,t,var(1:nx), [real(V);imag(V)], [real(I);imag(I)], var(nx+(1:nu)));
option = optimoptions('fsolve', 'MaxFunEvals', inf, 'MaxIterations', 100, 'Display','iter-detailed');
result = fsolve(func,[ones(nx+nu,1)], option);

xst = result(1:nx)
ust = result(nx+(1:nu))

function constraint = fx(obj,t,x,V,I,u)
    [dx,con] = obj.get_dx_constraint(t,x,V,I,u);
    constraint = [dx;con];
end