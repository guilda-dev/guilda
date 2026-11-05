% F19 モデルのコンストラクタの入力検査 (Issue #101)
%
%   パラメータの列の不足と未知の名前は ID つきのエラーで止まる
%   コンストラクタのない負荷の子クラスが動く
%   発電機が無視する Q は警告される。組み込み系統では警告が出ない
%   local の下の PSS は親の key を示すエラーで止まる
%
% 実行: runtests("DebugScript.test_F19_model_constructor")  または  DebugScript.run_all("Features","F19")

% 共通設定 (各テストの前に毎回実行される)
s_miss   = "GUILDA:Component:MissingParameter";
s_name   = "GUILDA:Component:UnknownParameter";
s_q      = "GUILDA:Component:GeneratorQIgnored";


%% A table without a column names the missing column
bus = PowerNetwork().add_bus();
tab = table(1, 2, VariableNames=["M", "D"]);
ME = caught(@() bus.add_component("gen-1axis", parameter=tab));
assert(DebugScript.helper.msg_id(ME) == s_miss)
assert(contains(ME.message, "Xd") && ~contains(ME.message, "'M") && contains(ME.message, "table"))
assert(isempty(bus.a_Component))


%% A model column absent from parameter.csv names the column and the file
ME = caught(@() DebugScript.helper.GeneratorStub("1B001", nan, default_opt()));
assert(DebugScript.helper.msg_id(ME) == s_miss)
assert(contains(ME.message, "Zeta") && contains(ME.message, "parameter.csv"))


%% A complete table is still accepted, also with extra columns
gen = DebugScript.helper.GeneratorStub("1B001", table(1, 2, 3, VariableNames=["Zeta", "M", "Note"]), default_opt());
assert(gen.para_dynamics.tab_parameter.Zeta == 1 && gen.para_dynamics.tab_parameter.M == 2)


%% An unknown parameter name lists the allowed names
bus = PowerNetwork().add_bus();
ME = caught(@() bus.add_component("gen-park", parameter="NGT9"));
assert(DebugScript.helper.msg_id(ME) == s_name)
assert(contains(ME.message, "NGT9") && contains(ME.message, "NGT2") && contains(ME.message, "NGT8"))
assert(isempty(bus.a_Component))
assert(DebugScript.helper.msg_id(caught(@() bus.add_component("gen-park", parameter=["NGT2", "NGT6"]))) == s_name)


%% Known parameter names select the row of parameter.csv
bus = PowerNetwork().add_bus();
gen6 = bus.add_component("gen-1axis", parameter="NGT6");
gen8 = bus.add_component("gen-1axis", parameter='NGT8');
gen0 = bus.add_component("gen-1axis");
assert(gen6.para_dynamics.tab_parameter.Xd_p == 0.38)
assert(gen8.para_dynamics.tab_parameter.Xd_p == 0.35 && gen8.para_dynamics.tab_parameter.Xd == 1.2)
assert(gen0.para_dynamics.tab_parameter.Xd == 1.7 && gen0.para_dynamics.tab_parameter.Xd_p == 0.35)


%% A load subclass without a constructor works
ld = DebugScript.helper.LoadStub("2B003", nan, default_opt());
assert(ld.s_tag == "L2B003")
assert(isa(ld, "component.load.abstract") && ld.para_powerflow.P == 0.5)


%% Built-in loads keep their tags
bus = PowerNetwork().add_bus();
ld = bus.add_component("load-power", P=-0.8, Q=-0.3);
assert(startsWith(ld.s_tag, "LPQ1") && ld.para_powerflow.Q == -0.3)
assert(startsWith(bus.add_component("load-impedance", P=-0.1).s_tag, "LRX2"))


%% An ignored generator Q warns and is still replaced by NaN
bus = PowerNetwork().add_bus();
lastwarn("");
gen = bus.add_component("gen-park", P=0.5, Q=0.3);
[s_msg, s_id] = lastwarn(); s_id = DebugScript.helper.msg_id(s_msg, s_id);
assert(string(s_id) == s_q && contains(s_msg, "0.3") && contains(s_msg, gen.s_tag))
assert(isnan(gen.para_powerflow.Q))


%% The default Q and Q=NaN do not warn
bus = PowerNetwork().add_bus();
lastwarn("");
bus.add_component("gen-park", P=0.5);
bus.add_component("gen-park", P=0.5, Q=nan);
assert(string(lastwarn) == "")


%% Replacing a generator by a generator does not warn
net = DebugScript.helper.build_ieee14();
bus = net.a_Bus{1};
lastwarn("");
gen = bus.replace_component(bus.a_Component{1}.s_tag, "gen-classical");
s_id = DebugScript.helper.msg_id();
assert(string(s_id) ~= s_q && isnan(gen.para_powerflow.Q))


%% Built-in networks and the bundled CSV data do not warn about Q
c_net = {@() network.IEEE9bus(), @() network.IEEE14bus(), @() network.IEEE14bus_NoTap(), @() network.IEEE14bus_lossless(), ...
         @() network.IEEE68bus(), @() network.Ishizaki6Bus(), @() network.TEST31bus(), @() network.Txt3Bus(), @() network.Tutorial3bus(), ...
         @() network.IEEJ_EAST10(), @() network.IEEJ_EAST30(), @() network.IEEJ_WEST10(), @() network.IEEJ_WEST30()};
for i = 1:numel(c_net)
    s = warning("error", s_q);
    c_warn = onCleanup(@() warning(s));
    DebugScript.helper.quiet(c_net{i});
    clear c_warn
end


%% A PSS under a local controller names the key of the parent
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
lqr = controller.local_LQR("lqr1", Input="Vfield");
gen.add_local_controller(lqr);
pss = controller.pss.PSS1("pss1");
ME = caught(@() gen.add_local_controller(pss));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:PssParentKey")
assert(contains(ME.message, "'local'") && contains(ME.message, lqr.s_tag) && contains(ME.message, "'avr'"))
assert(isempty(pss.a_Component))


%% A PSS without an AVR has an ID and says what to do
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
ME = caught(@() gen.add_local_controller(controller.pss.PSS1("pss1")));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:NotExtAvr" && contains(ME.message, "Attach an AVR"))


function opt = default_opt()
    % The name-value options of Bus.add_component, as a subclass constructor receives them
    opt = struct("P", 0.5, "Q", 0, "baseMVA", 100, "Pmin", -inf, "Pmax", inf, "Qmin", -inf, "Qmax", inf, ...
                 "OPFinit_P0", 0, "OPFinit_Q0", 0, "OPFcost_HP", nan, "OPFcost_HQ", 0, "OPFcost_fP", nan, ...
                 "OPFcost_fQ", 0, "OPFcost_startup", 0, "OPFcost_shutdown", 0, "Xaxis", nan, "Yaxis", nan, ...
                 "Marker", "o", "MidXaxis", "", "MidYaxis", "");
end

function ME = caught(fcn)
    % Run fcn, which must stop with an error, and return the error
    ME = [];
    try
        fcn();
    catch ME
    end
    assert(~isempty(ME), "No error was raised.")
    ME = struct("identifier", string(DebugScript.helper.msg_id(ME)), "message", string(ME.message));
end
