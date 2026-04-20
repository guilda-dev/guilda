% レトロフィット制御器(controller.local_LQR_retrofit)のための実装
% 真の線形環境モデルを取得するための関数
function [environment, subsystem] = get_environment(net, idx, do_check)

if nargin<3
    do_check = false;
end

[~, sys_env] = net.get_sys_area(idx, [], true);
G = sys_env('I_bound', 'V_bound');
sys1 = tools.darrayfun(@(i) net.a_bus{i}.component.get_sys(), idx);
[~, ~, C, D] = ssdata(sys1('I_polar', 'Vin_polar'));
sys_V = myinv(G-D)*C;
environment = sys_V(:, [1,3]);
environment.InputGroup.delta_m = 1;
environment.InputGroup.E_m = 2;
environment.OutputGroup.V_polar_m = 1:2;
environment.OutputGroup.angleV_m = 1;
environment.OutputGroup.absV_m = 2;

subsystem = net.a_bus{idx}.component.get_sys();
subsystem.InputGroup.u = [subsystem.InputGroup.u_avr1, subsystem.InputGroup.Pm];
subsystem = subsystem({'delta', 'omega', 'E'}, {'Vin_polar', 'u'});

if do_check
    sys_cat = blkdiag(subsystem, environment);
    ig = sys_cat.InputGroup; og = sys_cat.OutputGroup;
    feedin = [ig.delta_m, ig.E_m, ig.Vin_polar];
    feedout = [og.delta, og.E, og.V_polar_m];
    sys_fb = feedback(sys_cat, eye(numel(feedin)), feedin, feedout, 1);
    sys_fb = sys_fb({'V_polar_m', 'delta', 'omega', 'E'}, 'u');

    str_idx = num2str(idx);
    sys = net.get_sys_polar();
    sys.OutputGroup.V_polar_m = sys.OutputGroup.(['V', str_idx]);
    og_xn = sys.OutputGroup.(['x', str_idx]);
    sys.OutputGroup.delta = og_xn(1);
    sys.OutputGroup.omega = og_xn(2);
    sys.OutputGroup.E = og_xn(3);
    sys = sys({'V_polar_m', 'delta', 'omega', 'E'}, ['u', str_idx]);
    bode(sys, sys_fb); % 一致を確認
end

end


function sys_out = myinv(sys)

[A, B, C, D] = ssdata(sys);

Anew = A-B/D*C;
Bnew = B/D;
Cnew = -D\C;
Dnew = inv(D);

sys_out = ss(Anew, Bnew, Cnew, Dnew);

end