% F80 組み立て済みの tab_parameter と msg の定義を持っておく (GUI の高速化で見つかった重い処理)
%
% PowerSystemModel.get.tab_parameter は組み立てた table を持っておき、編集のたびに作り直す。
% どの経路で編集しても、次に読むと新しい値が返ること、持っている table が a_Parameter から
% 組み立て直した table と等しいことを確かめる。msg はクラスごとの定義を一度だけ読む。
%
% 実行: runtests("DebugScript.test_F80_parameter_table_cache")  または  DebugScript.run_all("Features","F80")

%% A direct write of tab_parameter is read back at once
net = network.IEEE9bus();
bus = net.a_Bus{1};
bus.tab_parameter;                                   % build and keep the table
V = bus.tab_parameter.powerflow.V;
bus.tab_parameter.powerflow.V = V + 0.01;
assert(bus.tab_parameter.powerflow.V == V + 0.01)
assert_fresh(bus)

%% A write of a Parameter container is read back through the owner
net = network.IEEE9bus();
comp = net.a_Bus{2}.a_Component{1};
comp.tab_parameter;
para = comp.a_Parameter{cellfun(@(p) p.s_tag == "dynamics", comp.a_Parameter)};
D = para.tab_parameter.D;
para.tab_parameter.D = D + 1;
assert(comp.tab_parameter.dynamics.D == D + 1)
assert_fresh(comp)

%% set_parameter and set_layout are read back
net = network.IEEE9bus();
cellfun(@(b) b.tab_parameter, net.a_Bus, "UniformOutput", false);
tab = net.get_parameter("powerflow", Key="load-impedance");
tab.P = 2*tab.P;
net.set_parameter("powerflow", tab);
comp = net.get_element(tab.Properties.RowNames{1});
assert(comp.tab_parameter.powerflow.P == tab.P(1))
assert_fresh(comp)
L = net.get_layout();
s_bus = L.tab_bus.Tag(1);
X = 0.3;                                             % a new X for bus 1 (IEEE9bus has X = 0.5)
net.set_layout(struct("tab_bus", table(s_bus, X, 'VariableNames', ["Tag", "X"])));
bus = net.get_element(s_bus);
assert(abs(bus.tab_parameter.graph.X - X) < 1e-12)
assert_fresh(bus)

%% A rename of a container renames the column
net = network.IEEE9bus();
bus = net.a_Bus{1};
bus.tab_parameter;
para = bus.a_Parameter{cellfun(@(p) p.s_tag == "operation", bus.a_Parameter)};
para.s_tag = "operationX";
assert(ismember("operationX", string(bus.tab_parameter.Properties.VariableNames)))
assert(~ismember("operation", string(bus.tab_parameter.Properties.VariableNames)))
assert_fresh(bus)
para.s_tag = "operation";
assert_fresh(bus)

%% A rejected write keeps the stored values
net = network.IEEE9bus();
bus = net.a_Bus{1};
tp = bus.tab_parameter;
try
    bus.tab_parameter.powerflow.V = "x";
    error("DebugScript:F80", "the write should fail")
catch ME
    assert(ME.identifier ~= "DebugScript:F80", ME.message)
end
assert(isequaln(bus.tab_parameter, tp))
assert_fresh(bus)

%% The kept table is not saved and is built again after a load
net = network.IEEE9bus();
bus = net.a_Bus{1};
bus.tab_parameter.powerflow.V = 1.04;
f = [tempname, '.mat'];
c = onCleanup(@() delete(f));
save(f, "net");
sct = load(f);
bus2 = sct.net.a_Bus{1};
assert(~ismember("tab_parameterCache", string(properties(bus2))))
assert(bus2.tab_parameter.powerflow.V == 1.04)
assert_fresh(bus2)

%% An exported and imported network has the edited values
net = network.IEEE9bus();
comp = net.a_Bus{2}.a_Component{1};
comp.tab_parameter.dynamics.D = 7;
s_dir = tempname;
c = onCleanup(@() rmdir(s_dir, "s"));
evalc("net.export(s_dir);");
evalc("net2 = PowerNetwork.import(s_dir);");
comp2 = net2.get_element(comp.s_tag);
assert(comp2.tab_parameter.dynamics.D == 7)
assert_fresh(comp2)

%% msg gives the same text on repeated calls and after clear msg
net = network.IEEE9bus();
s1 = error_message(@() net.get_element("NoSuchTag"));
s2 = error_message(@() net.get_element("NoSuchTag"));
clear msg
s3 = error_message(@() net.get_element("NoSuchTag"));
assert(s1 ~= "" && s1 == s2 && s2 == s3)

%% Local functions
function assert_fresh(m)
    % The kept table equals the table built again from the containers.
    c_tab = cellfun(@(p) p.tab_parameter, m.a_Parameter, 'UniformOutput', false);
    sv_tag = string(cellfun(@(p) p.s_tag, m.a_Parameter, 'UniformOutput', false));
    assert(isequaln(m.tab_parameter, table(c_tab{:}, 'VariableNames', sv_tag)))
end

function s = error_message(f)
    s = "";
    try
        f();
    catch ME
        s = string(ME.message);
    end
end
