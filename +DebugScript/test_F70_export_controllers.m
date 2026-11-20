% F70 制御器の書き出しと読み込み (notes/export-controllers.md)
%
%   export はすべてのローカル制御器 (既定の Static を含む) を local_controller/<key>/parameter.csv に、
%   グローバル制御器を global_controller/<key>/parameter.csv に書く。import は local_controller/ を
%   その系統のローカル制御器のすべてとして戻し (作成時の Static は外す)、グローバル制御器を戻す。
%   表の外のコンストラクタ引数 (get_option: local_LQR の Q, R, Input, V0、Retrofit の Q, R) は option.json に書く。
%   往復の後、タグ、キー、親、パラメータの表、get_option、変数の対応 (get_variable_map)、シナリオの表、
%   simulate の結果が元と等しい。知らないキー、知らない Component、枠に合わない行は系統を
%   変える前にエラーになる。
%
% 実行: runtests("DebugScript.test_F70_export_controllers")  または  DebugScript.run_all("Features","F70")


%% IEEE9bus with a PSS trip survives a round trip and gives the same simulation
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
sc  = net.add_scenario("psstrip");
sc.add_trip("B001SG1CP2", 1);
[net2, c] = round_trip(net, "probe9"); %#ok<ASGLU>
check_same(net, net2)
check_simulate(net, net2, "psstrip")


%% An AVR_ST1 with a PSS1 and a PSS under the Static AVR keep their parents
net = no_controller_9bus();
g1  = net.a_Bus{1}.a_Component{1};
g1.add_local_controller("avr-ST1", parameter=struct(kap=30, Limiter=false));
g1.add_local_controller("pss-PSS1", parameter=struct(kpss=5));
g2  = net.a_Bus{2}.a_Component{1};
g2.add_local_controller("avr-static");
g2.add_local_controller("pss-PSS1", parameter=struct(kpss=3));
DebugScript.helper.quiet(@() net.initialize);
[net2, c] = round_trip(net, "Nested"); %#ok<ASGLU>
check_same(net, net2)
avr = net2.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(avr.key == "avr-ST1" && avr.a_LocalController{1}.key == "pss-PSS1")
assert(islogical(avr.tab_parameter.dynamics.Limiter) && ~avr.tab_parameter.dynamics.Limiter)
avr = net2.a_Bus{2}.a_Component{1}.a_LocalController{1};
assert(avr.key == "avr-static" && avr.a_LocalController{1}.key == "pss-PSS1")
assert(isempty(net2.a_Bus{3}.a_Component{1}.a_LocalController))


%% IEEE68bus survives a round trip
net = DebugScript.helper.quiet(@() network.IEEE68bus(LocalController=true));
[net2, c] = round_trip(net, "Net68"); %#ok<ASGLU>
check_same(net, net2)


%% IEEE68bus gives the same simulation after a round trip
net = DebugScript.helper.quiet(@() network.IEEE68bus(LocalController=true));
sc  = net.add_scenario("fault", Time=[0, 2]);
sc.add_fault("B001", [0.1, 0.15]);
[net2, c] = round_trip(net, "Net68"); %#ok<ASGLU>
check_simulate(net, net2, "fault")


%% IEEJ_EAST10 keeps the AVR_DC1 limiter and the IEEJ governors
net = DebugScript.helper.quiet(@() network.IEEJ_EAST10(LocalController=true));
[net2, c] = round_trip(net, "East10"); %#ok<ASGLU>
check_same(net, net2)
avr = net2.a_Bus{1}.a_Component{1}.a_LocalController{1};
assert(avr.key == "avr-DC1" && islogical(avr.tab_parameter.dynamics.Limiter) && avr.tab_parameter.dynamics.Limiter)
sv_gov = cellfun(@(comp) string(comp.governor.key), tools.vcellfun(@(b) b.a_Component(1), net2.a_Bus(1:10)));
assert(isequal(unique(sv_gov), ["gov-LPT1"; "gov-LPT4"]))


%% Tutorial10bus keeps every controller class, the LQR input, the Retrofit and the AGC
net = DebugScript.helper.quiet(@() network.Tutorial10bus());
agc = net.a_GlobalController{1};
tab = agc.tab_parameter.dynamics;
tab.kP = [100; 120; 140; 160];
agc.tab_parameter.dynamics = tab;
DebugScript.helper.quiet(@() net.initialize);
sc  = net.add_scenario("agctrip", Time=[0, 2]);
sc.add_trip(agc.s_tag, 0.5);
sc.add_fault("B007", [0.1, 0.15]);
[net2, c, s_path] = round_trip(net, "Tutorial"); %#ok<ASGLU>
check_same(net, net2)
check_simulate(net, net2, "agctrip")
lqr = net2.a_Bus{3}.a_Component{1}.a_LocalController{1};
assert(lqr.key == "local-LQR" && isequal(lqr.get_option().Input, "Vfield"))
assert(isequal(lqr.K, net.a_Bus{3}.a_Component{1}.a_LocalController{1}.K))
pss = net2.a_Bus{4}.a_Component{1}.avr.a_LocalController{1};
assert(pss.key == "pss-retrofit" && net2.a_Bus{4}.a_Component{1}.avr.key == "avr-static")
assert(isfile(fullfile(s_path, "local_controller", "local-LQR", "option.json")))
assert(~isfile(fullfile(s_path, "local_controller", "avr-ST1", "option.json")), "get_option が空のキーは書かない")
assert(~isfile(fullfile(s_path, "global_controller", "agc-PI", "option.json")))


%% option.json keeps matrices, a complex V0, a default Input and empty weights
net = no_controller_9bus();
g1  = net.a_Bus{1}.a_Component{1};
n_x = numel(g1.sv_x);
g1.add_local_controller("local-LQR", parameter=struct(Input=["Vfield"; "Pmech"], Q=1:n_x, R=[1, 0.2; 0.2, 2], V0=1.02+0.01i));
g2  = net.a_Bus{2}.a_Component{1};
g2.add_local_controller("avr-static");
g2.add_local_controller("pss-retrofit", parameter=struct(Q=1:n_x, R=0.01));
g3  = net.a_Bus{3}.a_Component{1};
g3.add_local_controller("avr-static");
g3.add_local_controller("pss-retrofit");
g3.add_local_controller("gov-static");
DebugScript.helper.quiet(@() net.initialize);
[net2, c, s_path] = round_trip(net, "Options"); %#ok<ASGLU>
check_same(net, net2)
sct = jsondecode(fileread(fullfile(s_path, "local_controller", "local-LQR", "option.json")));
assert(isequal(sct.B001SG1CL1.V0, struct("re", 1.02, "im", 0.01)))
con = net2.a_Bus{3}.a_Component{1}.avr.a_LocalController{1};
assert(isempty(con.Q) && isempty(con.R), "既定の重みは空のまま")
assert(isequal(net2.a_Bus{2}.a_Component{1}.avr.a_LocalController{1}.Q, diag(1:n_x)))


%% A global controller keeps its tag in a folder of another name, and its parameters per unit
net = DebugScript.helper.quiet(@() network.IEEE14bus());
agc = DebugScript.helper.quiet(@() net.add_global_controller("agc-PI", ["B001SG1", "B002SG1", "B003SG1"], parameter=struct(kP=50)));
tab = agc.tab_parameter.dynamics;
tab.kP(2) = 70;
tab.alpha(3) = 0.5;
agc.tab_parameter.dynamics = tab;
DebugScript.helper.quiet(@() net.initialize);
sc  = net.add_scenario("agctrip", Time=[0, 2]);
sc.add_trip(agc.s_tag, 0.5);
sc.add_input("B003SG1", "Pmech", -0.05, [0.1, Inf]);
[net2, c] = round_trip(net, "OtherName"); %#ok<ASGLU>
assert(net2.s_tag == "OtherName" && string(net2.a_GlobalController{1}) == "PowerNetworkAGC1")
check_same(net, net2)
check_simulate(net, net2, "agctrip")


%% A network without controllers writes an empty local_controller folder and stays without them
net = no_controller_9bus();
[net2, c, s_path] = round_trip(net, "NoController"); %#ok<ASGLU>
s_dir = fullfile(s_path, "local_controller");
assert(isfolder(s_dir) && numel(dir(s_dir)) == 2, "空のフォルダ")
assert(~isfolder(fullfile(fileparts(s_dir), "global_controller")))
for i_bus = 1:3
    assert(isempty(net2.a_Bus{i_bus}.a_Component{1}.a_LocalController))
end
check_same(net, net2)


%% Two components with controllers on one bus get their own controllers
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gen2 = net.a_Bus{2}.add_component("gen-1axis", P=0.1);
gen.add_local_controller("avr-ST1", parameter=struct(kap=10));
gen2.add_local_controller("avr-ST1", parameter=struct(kap=20));
gen2.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
[net2, c] = round_trip(net, "TwoGen"); %#ok<ASGLU>
check_same(net, net2)
assert(net2.a_Bus{2}.a_Component{2}.a_LocalController{1}.tab_parameter.dynamics.kap == 20)


%% A wrong controller folder stops before the network changes
net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=true));
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Bad")));
s_lc   = fullfile(s_path, "local_controller");
% 知らないキー
movefile(fullfile(s_lc, "avr-ST1"), fullfile(s_lc, "avr-Unknown"));
check_import_error(s_path, "GUILDA:import:UnknownControllerKey")
movefile(fullfile(s_lc, "avr-Unknown"), fullfile(s_lc, "avr-ST1"));
% 知らない Component
s_file = fullfile(s_lc, "pss-PSS1", "parameter.csv");
s_text = fileread(s_file);
writelines(replace(s_text, "B002SG1,", "B099SG1,"), s_file);
check_import_error(s_path, "GUILDA:import:UnknownComponent")
% AVR のない PSS
writelines(s_text, s_file);
writelines(regexprep(fileread(fullfile(s_lc, "avr-ST1", "parameter.csv")), "B003SG1,[^\n]*\n", ""), fullfile(s_lc, "avr-ST1", "parameter.csv"));
check_import_error(s_path, "GUILDA:import:ControllerSlots")
% 同じ枠に 2 つ
copyfile(fullfile(s_lc, "avr-ST1"), fullfile(s_lc, "avr-DC1"));
check_import_error(s_path, "GUILDA:import:ControllerSlots")


%% Overwrite replaces the controller folders
net = DebugScript.helper.quiet(@() network.IEEE14bus());
DebugScript.helper.quiet(@() net.add_global_controller("agc-PI", ["B001SG1", "B002SG1"]));
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
mkdir(fullfile(s_path, "local_controller", "avr-ST1"));
net = DebugScript.helper.quiet(@() network.IEEE14bus());
DebugScript.helper.quiet(@() net.export(s_path, Overwrite=true));
assert(~isfolder(fullfile(s_path, "global_controller")))
assert(~isfolder(fullfile(s_path, "local_controller", "avr-ST1")))
assert(isfolder(fullfile(s_path, "local_controller", "avr-static")))


function [net2, c, s_path] = round_trip(net, s_name)
    % export to a new folder s_name and import it with Initialize=true
    [s_dir, c] = temp_folder();
    s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, s_name)));
    net2   = DebugScript.helper.quiet(@() PowerNetwork.import(s_path));
end

function check_same(net, net2)
    % The tags, keys, parents, parameter tables, variable map and scenario tables of two networks
    assert(isequal(string(net.a_Bus), string(net2.a_Bus)))
    assert(isequal(string(net.a_Branch), string(net2.a_Branch)))
    [sv_con, c_tab]   = controller_list(net);
    [sv_con2, c_tab2] = controller_list(net2);
    assert(isequal(sv_con, sv_con2), "制御器のタグ、キー、親")
    assert(isequaln(c_tab, c_tab2), "制御器の表")
    assert(isequal(string(net.a_GlobalController), string(net2.a_GlobalController)))
    for k = 1:numel(net.a_GlobalController)
        gc  = net.a_GlobalController{k};
        gc2 = net2.a_GlobalController{k};
        assert(gc.key == gc2.key && isequaln(gc.tab_parameter, gc2.tab_parameter), string(gc))
        assert(isequaln(gc.get_option(), gc2.get_option()), string(gc))
        assert(isequal(cellfun(@string, gc.controlledUnits), cellfun(@string, gc2.controlledUnits)), string(gc))
    end
    c_map  = cell(1, 4);
    c_map2 = cell(1, 4);
    [c_map{:}]  = net.get_variable_map();
    [c_map2{:}] = net2.get_variable_map();
    % the equilibria agree to the power-flow tolerance: a network initialized twice starts its
    % second power flow from the first solution, the imported one from the flat start
    tab  = c_map{1};
    tab2 = c_map2{1};
    assert(max(abs(tab.Equilibrium - tab2.Equilibrium), [], "all") < 1e-9, "get_variable_map Equilibrium")
    c_map{1}  = removevars(tab, "Equilibrium");
    c_map2{1} = removevars(tab2, "Equilibrium");
    assert(isequaln(c_map, c_map2), "get_variable_map")
    assert(isequal(string(net.a_Scenario), string(net2.a_Scenario)))
    for k = 1:numel(net.a_Scenario)
        sc1 = net.a_Scenario{k};
        sc2 = net2.a_Scenario{k};
        assert(isequaln(sc1.tab_event, sc2.tab_event) && isequaln(sc1.tab_offset, sc2.tab_offset) ...
               && isequaln(sc1.tab_input, sc2.tab_input) && isequal(sc1.Time, sc2.Time), sc1.s_tag)
    end
end

function [sv_con, c_tab] = controller_list(net)
    % "<component> <controller> <key> <parent>" for every local controller, and their tab_parameter
    sv_con = strings(0, 1);
    c_tab  = cell(0, 1);
    for i_bus = 1:numel(net.a_Bus)
        for comp = reshape(net.a_Bus{i_bus}.a_Component, 1, [])
            a_con = comp{1}.a_LocalController;
            for k = 1:numel(comp{1}.a_LocalController)
                a_con = [a_con; comp{1}.a_LocalController{k}.a_LocalController]; %#ok<AGROW>
            end
            for k = 1:numel(a_con)
                con = a_con{k};
                sv_con(end+1, 1) = join([string(comp{1}), string(con), con.key, string(con.a_Component)]); %#ok<AGROW>
                c_tab{end+1, 1}  = {con.tab_parameter, con.get_option()}; %#ok<AGROW>
            end
        end
    end
end

function check_simulate(net, net2, s_scenario)
    r1 = DebugScript.helper.quiet(@() net.simulate(s_scenario, Progress="none"));
    r2 = DebugScript.helper.quiet(@() net2.simulate(s_scenario, Progress="none"));
    assert(isequaln(r1.rv_t, r2.rv_t) && isequaln(r1.rm_variable, r2.rm_variable), s_scenario)
end

function check_import_error(s_path, s_id)
    % The import stops with s_id and leaves Network= unchanged
    net = PowerNetwork("Target");
    try
        DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Network=net, Initialize=false));
        error("F70:NoError", "no error: " + s_id)
    catch ME
        assert(string(DebugScript.helper.msg_id(ME)) == s_id, ME.message)
    end
    assert(isempty(net.a_Bus), s_id)
end

function [s_dir, c] = temp_folder()
    s_dir = tempname;
    mkdir(s_dir);
    c = onCleanup(@() rmdir(s_dir, "s"));
end

function net = no_controller_9bus()
    % IEEE9bus で、どの機器にも制御器 (既定の Static も) がない系統
    net = DebugScript.helper.quiet(@() network.IEEE9bus(LocalController=false));
    for b = 1:numel(net.a_Bus)
        for comp = reshape(net.a_Bus{b}.a_Component, 1, [])
            for con = reshape(comp{1}.a_LocalController, 1, [])
                comp{1}.remove_local_controller(con{1}.s_tag, RemoveNested=true);
            end
        end
    end
    DebugScript.helper.quiet(@() net.initialize);
end
