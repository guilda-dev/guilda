% F72 系統の要素を引くメソッド (get_element, get_element_table, get_parameter, set_parameter) と disp_summary の箇条書き
%
%   get_element はタグから母線・ブランチ・機器・ローカル制御器・グローバル制御器・シナリオを返す
%   (複数なら cell、ないタグはエラー)。get_element_table は 1 行 1 要素の表 (文字列の列) で、Kind と
%   Owner で絞れる。get_parameter はパラメータのグループを行がタグの表で返し、set_parameter は
%   その表を書き戻す (tab_parameter への書き込みと同じ検査と編集の記録、誤りは何も書かずにエラー)。
%   disp_summary は箇条書きの一覧のあとに表を出し、initialize 前は平衡点の列を省く。
%
% 実行: runtests("DebugScript.test_F72_network_element_methods")  または  DebugScript.run_all("Features","F72")


%% get_element returns each kind of element and a cell for several tags
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
sc  = net.add_scenario("fault");
assert(net.get_element("B001") == net.a_Bus{1})
assert(net.get_element("EL004") == net.a_Branch{4})
gen = net.a_Bus{1}.a_Component{1};
assert(net.get_element("B001SG1") == gen)
assert(net.get_element("B001SG1CA1") == gen.a_LocalController{1})
assert(net.get_element("B001SG1CP2") == gen.a_LocalController{1}.a_LocalController{1})   % PSS under the AVR
assert(net.get_element("fault") == sc)
c = net.get_element(["B002", "B002SG1CG1"]);
assert(iscell(c) && numel(c) == 2 && c{1} == net.a_Bus{2} && isa(c{2}, "LocalController"))


%% get_element finds a global controller and names a missing tag
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
gc  = DebugScript.helper.quiet(@() net.add_global_controller("agc-PI", {"B001SG1", "B002SG1"}));
assert(net.get_element(gc.s_tag) == gc)
try
    net.get_element(["B001", "NoSuchTag"]);
    error("no error")
catch e
    assert(e.message ~= "no error" && contains(e.message, "'NoSuchTag'"), e.message)
end


%% get_element_table lists every element with string columns
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
tab = net.get_element_table();
assert(isequal(string(tab.Properties.VariableNames), ...
    ["Tag", "Kind", "Key", "Class", "Role", "Bus", "Parent", "From", "To", "State", "Input", "Output"]))
assert(all(varfun(@isstring, tab, OutputFormat="uniform")))
assert(height(tab) == 9 + 9 + 6 + 9)
assert(isequal(string(tab.Properties.RowNames), tab.Tag))
r = tab("B001SG1", :);
assert(r.Kind == "component" && r.Key == "gen-1axis" && r.Bus == "B001" && r.Parent == "B001")
assert(r.State == "delta, omega, Eq" && r.Input == "Pmech, Vfield" && r.Output == "omega, Ifield")
r = tab("B001SG1CP2", :);
assert(r.Kind == "local" && r.Role == "pss" && r.Parent == "B001SG1CA1" && r.Bus == "B001")
r = tab("B001", :);
assert(r.Kind == "bus" && r.Key == "" && r.Bus == "B001" && r.Parent == "" && r.State == "")


%% get_element_table filters by Kind and Owner and gives From and To of branches
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
tab = net.get_element_table(Kind="branch");
assert(height(tab) == 9 && all(tab.Kind == "branch"))
assert(tab.From("ET001") == "B001" && tab.To("ET001") == "B004")
assert(all(net.get_element_table(Kind=["bus", "component"]).From == ""))
tab = net.get_element_table(Owner="B001SG1");
assert(isequal(tab.Tag, ["B001SG1CA1"; "B001SG1CP2"; "B001SG1CG1"]))
tab = net.get_element_table(Owner="B001", Kind="local");
assert(height(tab) == 3 && all(tab.Bus == "B001"))
assert(height(net.get_element_table(Owner="B004")) == 0)
try
    net.get_element_table(Owner="Nope");
    error("no error")
catch e
    assert(contains(e.message, "'Nope'"), e.message)
end


%% get_parameter and set_parameter round trip and scale the loads
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
tab = net.get_parameter("powerflow", Key="load-impedance");
assert(isequal(string(tab.Properties.RowNames), ["B005LRX1"; "B006LRX1"; "B008LRX1"]))
assert(isequal(string(tab.Properties.VariableNames), ["P", "Q"]))
DebugScript.helper.quiet(@() net.initialize);
net.set_parameter("powerflow", tab);                          % unchanged: no edit
assert(isempty(net.sct_stale.powerflow))
P0 = tab.P;
tab.P = 1.5*tab.P;
net.set_parameter("powerflow", tab);
assert(isequal(net.get_parameter("powerflow", Key="load-impedance").P, 1.5*P0))
assert(net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P == 1.5*P0(1))
assert(numel(net.sct_stale.powerflow) == 3 && contains(net.sct_stale.powerflow(1), "powerflow/B005LRX1: edit P"))


%% get_parameter selects by Class and Owner and sets costs of the generators
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
tab = net.get_parameter("dynamics", Key="gen-1axis");
assert(isequal(tab.M, [100; 18; 12]))
assert(height(net.get_parameter("powerflow", Class="Bus")) == 9)
assert(height(net.get_parameter("operation", Class="Branch")) == 9)
assert(isequal(string(net.get_parameter("dynamics", Owner="B001SG1CA1").Properties.RowNames), "B001SG1CP2"))
% loads have no dynamics parameters: left out
assert(height(net.get_parameter("dynamics", Class="Component", Key=["gen-1axis", "load-impedance"])) == 3)
tab = net.get_parameter("OPF", Key="gen-1axis");
tab{:, ["HP", "fP"]} = [0.02 2; 0.03 1.5; 0.025 1.8];
net.set_parameter("OPF", tab(:, ["HP", "fP"]));
assert(net.a_Bus{2}.a_Component{1}.tab_parameter.OPF.HP == 0.03)
assert(net.a_Bus{2}.a_Component{1}.tab_parameter.OPF.fQ == 0)                    % columns not given stay
net.set_parameter("dynamics", table(3, VariableNames="D", RowNames="B003SG1"));  % one value
assert(net.a_Bus{3}.a_Component{1}.tab_parameter.dynamics.D == 3)


%% get_parameter joins mixed models with the union of the columns and a Key column
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
tab = net.get_parameter("dynamics", Owner="B001SG1CA1");                % one model: no Key column
assert(~ismember("Key", tab.Properties.VariableNames))
tab = net.get_parameter("dynamics", Owner="B001SG1");                   % AVR and PSS of B001SG1
assert(string(tab.Properties.VariableNames(1)) == "Key")
assert(isequal(string(tab.Properties.RowNames), ["B001SG1CA1"; "B001SG1CP2"]))
assert(isequal(tab.Key, [string(net.get_element("B001SG1CA1").key); string(net.get_element("B001SG1CP2").key)]))
tab_a = net.get_element("B001SG1CA1").tab_parameter.dynamics;
tab_p = net.get_element("B001SG1CP2").tab_parameter.dynamics;
sv_a = string(tab_a.Properties.VariableNames);  sv_p = string(tab_p.Properties.VariableNames);
assert(isequal(string(tab.Properties.VariableNames), ["Key", unique([sv_a, sv_p], "stable")]))
for s = setdiff(sv_p, sv_a)
    assert(all(ismissing(tab{"B001SG1CA1", s})), s)                    % a parameter the AVR has not: NaN
end
assert(isequal(tab{"B001SG1CP2", sv_p}, tab_p{1, sv_p}))
tab.(sv_p(1))(2) = 2*tab.(sv_p(1))(2);                                  % written back: Key and fills skipped
net.set_parameter("dynamics", tab);
assert(net.get_element("B001SG1CP2").tab_parameter.dynamics.(sv_p(1)) == tab.(sv_p(1))(2))
s_only = setdiff(sv_p, sv_a, "stable");
bad = tab;  bad.(s_only(1))(1) = 1;                                    % a value the AVR has no parameter for
expect_error(@() net.set_parameter("dynamics", bad), "B001SG1CA1")
% governors of two IEEJ models (as in IEEJ_EAST30): one table, Prate of every governor
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
DebugScript.helper.quiet(@() net.a_Bus{1}.a_Component{1}.add_local_controller("gov-LPT1", parameter=struct(Prate=2, PLM=10)));
DebugScript.helper.quiet(@() net.a_Bus{2}.a_Component{1}.add_local_controller("gov-LPT4", parameter=struct(Prate=3, PLM=10)));
tab = net.get_parameter("dynamics", Class=["controller.governor.IEEJ_LPT1", "controller.governor.IEEJ_LPT4"]);
assert(isequal(tab.Key, ["gov-LPT1"; "gov-LPT4"]) && isequal(tab.Prate, [2; 3]))
assert(isnan(tab{1, "Tw"}) && isnan(tab{2, "Tch"}))                       % LPT1 has no Tw, LPT4 no Tch


%% get_parameter and set_parameter stop with clear errors and write nothing
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
expect_error(@() net.get_parameter("dynamic"), "dynamics")                         % unknown group
expect_error(@() net.get_parameter("dynamics", Key="no-key"), "Key, Class and Owner")
tab = net.get_parameter("powerflow", Key="load-impedance");
P0  = tab.P;
bad = tab;  bad.P = 2*bad.P;  bad.Properties.RowNames{3} = 'ZZ';
expect_error(@() net.set_parameter("powerflow", bad), "'ZZ'")
assert(isequal(net.get_parameter("powerflow", Key="load-impedance").P, P0))        % row 1 not written either
bad = tab;  bad.R = [1; 2; 3];
expect_error(@() net.set_parameter("powerflow", bad), "named R")
bad = tab;  bad.P = string(bad.P);
expect_error(@() net.set_parameter("powerflow", bad), "must be a double")
expect_error(@() net.set_parameter("powerflow", table(1, VariableNames="P")), "row names")
bad = net.get_parameter("graph", Class="Bus");  bad.Shape(1) = "hexagon";
expect_error(@() net.set_parameter("graph", bad), "hexagon")
assert(net.a_Bus{1}.tab_parameter.graph.Shape == "hbar")      % IEEE9bus bus 1 is a horizontal bar


%% disp_summary lists the elements as bullets and the equilibrium state
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
txt = evalc("net.disp_summary()");
assert(contains(txt, "- Buses: 9 (slack 1, PV 2, PQ 6); slack bus: B001"), txt)
assert(contains(txt, "- Branches: 9") && contains(txt, "    - pi: 6 (EL004, "))
assert(contains(txt, "- Components: 6") && contains(txt, "    - gen-1axis: 3 (B001SG1, B002SG1, B003SG1)"))
assert(contains(txt, "- Local controllers: 9 (avr 3, pss 3, governor 3)"))
assert(contains(txt, "- Global controllers: none") && contains(txt, "- Scenarios: none"))
assert(contains(txt, "- Equilibrium: up to date"))
assert(contains(txt, "Components: gen-1axis") && contains(txt, "theta") && contains(txt, "Xd_p"))
assert(~contains(txt, "1×0 table"))                                              % no empty groups
for s_head = ["Buses - parameter " + ["dynamics", "operation", "powerflow", "graph"], ...
              "Components: gen-1axis (component.generator.one_axis) - parameter " + ["dynamics", "operation", "powerflow", "OPF", "graph"], ...
              "Branches: pi (branch.pi) - parameter " + ["dynamics", "operation", "graph"]]
    assert(contains(txt, newline + s_head + newline), s_head)                          % every group under its heading
end
assert(~contains(txt, "load-impedance (component.load.impedance) - parameter dynamics"))  % the loads have no dynamics
assert(max(strlength(splitlines(txt))) <= 130)                                      % wide tables are printed in parts
txt = evalc("net.disp_summary(bus=false, branch=false, component=false)");
assert(contains(txt, "- Buses: 9") && ~contains(txt, "Components: gen-1axis"))


%% disp_summary before initialize leaves out the equilibrium columns
net = DebugScript.helper.build_9bus();
txt = evalc("net.disp_summary()");
assert(contains(txt, "no equilibrium yet") && contains(txt, "- Equilibrium: not computed"))
assert(~contains(txt, "theta") && contains(txt, "Xd"))
DebugScript.helper.quiet(@() net.initialize);
txt = evalc("net.disp_summary(parameter=false)");
assert(contains(txt, "theta") && contains(txt, "- Equilibrium: up to date") && ~contains(txt, "Xd") && ~contains(txt, "- parameter"))
net.a_Bus{2}.tab_parameter.powerflow.V = 1.03;
txt = evalc("net.disp_summary(bus=false, branch=false, component=false)");
assert(contains(txt, "- Equilibrium: out of date (powerflow/B002: edit V"), txt)
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{1}.a_Component{1}.tab_parameter.dynamics.D = 3;                  % equilibrium of the component only
txt = evalc("net.disp_summary(bus=false, branch=false, component=false)");
assert(contains(txt, "- Equilibrium: out of date (dynamics/B001SG1: edit D"), txt)


function expect_error(f, s_part)
    % f stops with an error whose message contains s_part
    try
        f();
    catch e
        assert(contains(e.message, s_part), e.message)
        return
    end
    error("no error (expected: %s)", s_part)
end
