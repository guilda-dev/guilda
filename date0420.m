% networkの定義（component等はついている状態)
net = network.IEEE68bus;

% 定インピーダンスモデルから定電力モデルへの切り替え
% net.a_bus{5}.set_component(component.load.power());
% net.a_bus{6}.set_component(component.load.power());
% net.a_bus{8}.set_component(component.load.power());

% 潮流計算
net.initialize()

% 入力偏差を与える
% time = [0, 10, 20, 30, 40, 60];
% 機器番号

% u_idx = [1, 5];
% u = [0, 0, 0.5, 0.5, 0, 0;
%      0, 0, 0.5, 0.5, 0, 0;
%      0, 0, 0.1, 0.1, 0, 0;
%      0, 0, 0.1, 0.1, 0, 0]*0.01;

time = [0, 5,   6,   9, 10, 60];
u_idx = 1;
u =    [0, 0, 0.1, 0.1,  0, 0;
        0, 0, 0.1, 0.1,  0, 0]*0.1;

% 制御器(agc)の追加
% con = controller.broadcast_PI_AGC(net, 1:3, 1:3, -5, -500);            
% net.add_controller_global(con);

% grid codeの追加(有効電力に関して）
gcode_gen = @(comp,t,x,V,I,u) code(comp,V,I);
idx_gen = find( tools.vcellfun(@(b) contains( class(b.component), 'generator'), net.a_bus ));
arrayfun(@(idx) net.a_bus{idx}.component.set_grid_code(gcode_gen), idx_gen);

% grid codeの追加(送電線に流れる電流に関して）
gcode_branch = @(obj,t,Vfrom, Vto) norm((Vto - Vfrom)/obj.x) < 1.5;
arrayfun(@(idx) net.a_branch{idx}.set_grid_code(gcode_branch), (1:length(net.a_branch))');

out = net.simulate(time, u, u_idx, ...
    'method', 'foh', ...
    'OutputFcn', {'omega'}, ...
    'tools', true, ...
    'grid_code', ['' ...
'control']);

function logic = code(comp,V,I)
P = V.'*I;
a = P > comp.alpha_st(1)*[0.99,1.01];
logic = xor(a(1),a(2));
end

% alpha_st=[P; Vfd; Vabs]
% logic = 1 (条件を満たすとき)
% logic = 0 (条件をみたさないとき)