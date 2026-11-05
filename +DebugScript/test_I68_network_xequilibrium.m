% Issue 68: net.rv_Xequilibrium の順序 (get_variable_map と一致)
%
% net.rv_Xequilibrium は読むだけでエラーになり、Component.rv_Xequilibrium_all は
% 入れ子の制御器 (AVR の下の PSS) の状態を落としていた。
%
% 実行: runtests("DebugScript.test_I68_network_xequilibrium")


%% Network equilibrium follows the variable map
net = build_net();
tab = net.get_variable_map();
tab = tab(tab.Kind == "x", :);
x   = net.rv_Xequilibrium;

assert(iscolumn(x) && numel(x) == height(tab))
assert(isequal(x, net.linearize().rv_point(1:height(tab))))

% 変数表の持ち主ごとに、その行の値が持ち主の平衡点と一致する
for owner = all_owners(net)'
    assert(isequal(x(tab.Owner == string(owner{1}.s_tag)), owner{1}.rv_Xequilibrium), ...
           "Owner " + owner{1}.s_tag)
end


%% Component equilibrium includes nested controllers
net  = build_net();
comp = net.a_Bus{1}.a_Component{1};
avr  = comp.a_LocalController{1};
pss  = avr.a_LocalController{1};
tab  = comp.get_variable_map();

assert(numel(pss.rv_Xequilibrium) > 0)
assert(numel(comp.rv_Xequilibrium_all) == nnz(tab.Kind == "x"))
assert(isequal(comp.rv_Xequilibrium_all, ...
               [comp.rv_Xequilibrium; avr.rv_Xequilibrium; pss.rv_Xequilibrium]))


%% Network without controllers follows the variable map
net = DebugScript.helper.build_9bus();
DebugScript.helper.quiet(@() net.initialize);
tab = net.get_variable_map();
assert(numel(net.rv_Xequilibrium) == nnz(tab.Kind == "x"))


%% Network without states returns an empty column
net = PowerNetwork();
assert(isequal(size(net.rv_Xequilibrium), [0 1]))


function net = build_net()
    % AVR と PSS を入れ子にした発電機、制御器なしの発電機、AGC を持つ 9 母線系統
    net  = DebugScript.helper.build_9bus();
    comp = net.a_Bus{1}.a_Component{1};
    comp.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
    c    = {net.a_Bus{2}.a_Component{1}; net.a_Bus{3}.a_Component{1}};
    agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
    net.add_global_controller(agc);
    DebugScript.helper.quiet(@() net.initialize);
end

function list = all_owners(net)
    % 状態を持つオブジェクトをすべて集める
    list = cell(0,1);
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            list = [list; controllers(net.a_Bus{i}.a_Component{j})]; %#ok<AGROW>
        end
    end
    list = [list; net.a_GlobalController];
end

function list = controllers(parent)
    list = {parent};
    for k = 1:numel(parent.a_LocalController)
        list = [list; controllers(parent.a_LocalController{k})]; %#ok<AGROW>
    end
end
