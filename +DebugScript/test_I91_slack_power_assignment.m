% Issue 91: スラック母線の残りの有効電力は Q = NaN の最初の機器が引き受ける
%
% 第1機器が引き受けていたので、負荷を発電機より先に追加すると負荷が発電し、CSV を往復すると
% 機器の順序が変わって運転点も変わっていた。
%
% 実行: runtests("DebugScript.test_I91_slack_power_assignment")  または  DebugScript.run_all("Features","I91")


%% A load added before the generator keeps its power, and the generator takes the rest
net = slack_network(["load", "gen"]);
tab = component_power(net);
assert(norm(tab{"load",["P","Q"]} - [-0.2, -0.05]) < 1e-8)
assert(tab{"gen","P"} > 0.4)
assert(kcl_residual(net) < 1e-8)


%% The order of the components does not change the operating point
tab1 = component_power(slack_network(["load", "gen"]));
tab2 = component_power(slack_network(["gen", "load"]));
assert(norm(tab1{["load","gen"],["P","Q"]} - tab2{["load","gen"],["P","Q"]}) < 1e-8)


%% A CSV round trip keeps the operating point
net = slack_network(["load", "gen"]);
[s_dir, c] = temp_folder();
s_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Net")));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path));
DebugScript.helper.quiet(@() net2.initialize);
tab1 = component_power(net);
tab2 = component_power(net2);
assert(string(net2.a_Bus{1}.a_Component{1}) ~= string(net.a_Bus{1}.a_Component{1}), "往復で順序が変わる系統で確かめる")
assert(norm(tab1{["load","gen"],["P","Q"]} - tab2{["load","gen"],["P","Q"]}) < 1e-8)
assert(norm(net.cv_Vequilibrium - net2.cv_Vequilibrium) < 1e-8)


%% With two Q = NaN components the first one takes the remaining P, and both share Q
net = slack_network(["load", "gen", "gen2"]);
tab = component_power(net);
assert(norm(tab{"load",["P","Q"]} - [-0.2, -0.05]) < 1e-8)
assert(abs(tab{"gen2","P"} - 0.05) < 1e-8)
assert(tab{"gen","P"} > 0.3)
assert(abs(tab{"gen","Q"}) > 1e-3 && abs(tab{"gen2","Q"}) > 1e-3)
assert(kcl_residual(net) < 1e-8)


%% Without Q = NaN the first component still takes the remaining P and Q
net = slack_network(["load", "load2"]);
tab = component_power(net);
assert(norm(tab{"load2",["P","Q"]} - [-0.1, -0.02]) < 1e-8)
assert(tab{"load","P"} > 0)
assert(kcl_residual(net) < 1e-8)


%% The INFO message names the component that takes the remaining power
net = slack_network(["load", "gen"], false);
evalc("net.a_Bus{1}.l_isSlack = false;");
s_out = string(evalc("net.a_Bus{1}.l_isSlack = true;"));
assert(contains(s_out, string(net.a_Bus{1}.a_Component{2})), s_out)
assert(~contains(s_out, string(net.a_Bus{1}.a_Component{1})), s_out)


%% Method="OPF" and "equilibrium" keep the powers they fix, whatever the order
net = slack_network(["load", "gen"], false);
DebugScript.helper.quiet(@() net.initialize(Method="OPF"));
tab1 = component_power(net);
assert(norm(tab1{"load",["P","Q"]} - [-0.2, -0.05]) < 1e-6)
assert(kcl_residual(net) < 1e-8)

DebugScript.helper.quiet(@() net.initialize(Method="equilibrium"));
tab2 = component_power(net);
assert(norm(tab1{["load","gen"],["P","Q"]} - tab2{["load","gen"],["P","Q"]}) < 1e-8)


% ---- local functions ----
function net = slack_network(sr_comp, l_init)
% B001 (スラック) に sr_comp の順で機器を追加した2母線系統
    arguments (Input)
        sr_comp  (1,:) string
        l_init   (1,1) logical = true
    end
    net = PowerNetwork("Slack");
    net.add_bus("V",1);
    net.add_bus();
    net.add_branch("pi",[1,2], "R",0.01, "X",0.085);
    bus = net.a_Bus{1};
    for str = sr_comp
        switch str
            case "load";  bus.add_component("load-power", "P",-0.2, "Q",-0.05);
            case "load2"; bus.add_component("load-power", "P",-0.1, "Q",-0.02);
            case "gen";   bus.add_component("gen-park", "P",0.1, "Q",nan);
            case "gen2";  bus.add_component("gen-park", "P",0.05, "Q",nan);
        end
    end
    net.a_Bus{2}.add_component("load-impedance", "P",-0.3, "Q",-0.1);
    evalc("bus.l_isSlack = true;");
    if l_init
        DebugScript.helper.quiet(@() net.initialize);
    end
end

function tab = component_power(net)
% スラック母線の機器の P, Q (行名は機器の設定 P から "load" などに対応づける)
    a_Comp = net.a_Bus{1}.a_Component;
    str = strings(numel(a_Comp),1);
    PQ  = zeros(numel(a_Comp),2);
    for i = 1:numel(a_Comp)
        comp = a_Comp{i};
        S = comp.c_Vequilibrium*conj(comp.c_Iequilibrium);
        PQ(i,:) = [real(S), imag(S)];
        str(i)  = name_of(comp.para_powerflow.P);
    end
    tab = array2table(PQ, "VariableNames",["P","Q"], "RowNames",str);
end

function str = name_of(r_P)
    r_all = [-0.2, -0.1, 0.1, 0.05];
    sr_all = ["load", "load2", "gen", "gen2"];
    [~, i] = min(abs(r_all - r_P));
    str = sr_all(i);
end

function r = kcl_residual(net)
    sv_Bus  = string(net.a_Bus);
    tab_Y   = net.get_admittance_matrix;
    r = max(abs(tab_Y{sv_Bus,sv_Bus}*net.cv_Vequilibrium - net.cv_Iequilibrium));
end

function [s_dir, c] = temp_folder()
    s_dir = tempname;
    mkdir(s_dir);
    c = onCleanup(@() rmdir(s_dir, "s"));
end
