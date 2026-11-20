net = network.IEEE14bus;

nonUnitBus = 7;
lin = odeLinearizer(net, nonUnitBus);
lin.getLinearSystem;

sys = lin.odeLinearSystem;

eig(sys.A)



%%

lin = odeLinearizer(net);
% [Ax_test1, Bx_test1, Cx_test1, Dx_test1] = lin.getLinearSystem();
% sys1 = lin.odeLinearSystem;
% eig(sys1.A)

[Ax_test2, Bx_test2, Cx_test2, Dx_test2] = lin.get_sys();
sys2 = lin.odeLinearSystem;
eig(sys2.A)


