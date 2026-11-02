% F22 モデルの契約の検査 (comp.validate, con.validate)
%
% 組み込みモデルは FAIL 0、不正モデルは該当する検査が FAIL になることを確認する。
% モデルの一覧は GUILDA.dictionary から作る (helper.model_classes)。新しいクラスは追加する
% だけで対象になり、add_component(key) や con(tag) で作れないと失敗して知らせる。
%
% 実行: runtests("DebugScript.test_F22_model_contract")  または  DebugScript.run_all("Features","F22")

% 共通設定 (各テストの前に毎回実行される)
tol_jacobi = 1e-5;


%% The model list matches the generated key lists and has the known models
% 手書きの一覧は下限の確認にだけ使う。試験の対象は GUILDA.dictionary から決まる
tab = DebugScript.helper.model_classes("Component");
assert(all(ismember(["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-power","load-impedance"], tab.Key)))
assert(isequal(sort(tab.Key), sort(generated_keys("@Bus", "add_component.m"))), "add_component")
assert(isequal(sort(tab.Key), sort(generated_keys("@Bus", "replace_component.m"))), "replace_component")
assert(numel(unique(tab.Key)) == height(tab) && all(tab.Key ~= ""), "機器のキーが重複または空")
tab = DebugScript.helper.model_classes("Branch");
assert(all(ismember(["pi","T","pi_transformer","two_winding_transformer"], tab.Key)))
assert(isequal(sort(tab.Key), sort(generated_keys("@PowerNetwork", "add_branch.m"))), "add_branch")
assert(numel(unique(tab.Key)) == height(tab) && all(tab.Key ~= ""), "ブランチのキーが重複または空")
assert(all(ismember(["controller.avr.AVR_ST1","controller.avr.AVR_DC1","controller.pss.PSS1","controller.local_LQR"], ...
                    DebugScript.helper.model_classes("LocalController").Class)))
assert(any(DebugScript.helper.model_classes("GlobalController").Class == "controller.agc.broadcast_PI_AGC"))


%% Every component key creates its class
tab = DebugScript.helper.model_classes("Component");
for k = 1:height(tab)
    [~, comp] = DebugScript.helper.build_3bus(tab.Key(k));
    assert(class(comp) == tab.Class(k) && comp.key == tab.Key(k), tab.Key(k))
end


%% Every component passes at the equilibrium
for key = DebugScript.helper.model_classes("Component").Key'
    [net, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net.initialize);
    assert_contract(comp, key);
end


%% Every component passes at a random point without an equilibrium
for key = DebugScript.helper.model_classes("Component").Key'
    [~, comp] = DebugScript.helper.build_3bus(key);
    assert_contract(comp, key);   % V, I の取り違えがない
end


%% Every component stays at the equilibrium in a simulation
for key = DebugScript.helper.model_classes("Component").Key'
    [net, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net.initialize);
    sol = DebugScript.helper.quiet(@() net.simulate([0,1]));
    r = sol.odeResults.Bus(2 + startsWith(key, "load")).Component(1);   % build_3bus の配置
    if ~isempty(comp.sv_x)
        assert(max(abs(r.X{:,:} - comp.rv_Xequilibrium'), [], "all") < 1e-6, key)
    end
end


%% Every generator passes with each row of parameter.csv
tab_csv = readtable(fullfile(fileparts(which("component.generator.abstract")), "parameter.csv"));
for key = generator_keys()
    for name = "NGT" + string(tab_csv.NGT)'
        [net, comp] = DebugScript.helper.build_3bus(key, parameter=name);
        DebugScript.helper.quiet(@() net.initialize);
        assert_contract(comp, key + " " + name);
    end
end


%% build_3bus passes the parameter of the component
tab_csv = readtable(fullfile(fileparts(which("component.generator.abstract")), "parameter.csv"));
[~, comp] = DebugScript.helper.build_3bus("gen-1axis", parameter="NGT8");
assert(comp.tab_parameter.dynamics.Xd == tab_csv.Xd(tab_csv.NGT == 8))
tab_para = comp.tab_parameter.dynamics;
tab_para.M = 50;
[~, comp] = DebugScript.helper.build_3bus("gen-1axis", parameter=tab_para);
assert(comp.tab_parameter.dynamics.M == 50)
[net, ~] = DebugScript.helper.build_3bus("gen-1axis", parameter="NGT8");
assert(net.a_Bus{1}.a_Component{1}.tab_parameter.dynamics.Xd == tab_csv.Xd(1), "slack の機器は既定のまま")
[~, comp] = DebugScript.helper.build_3bus("load-power", parameter="NGT8");   % 負荷は parameter を使わない
assert(isa(comp, "component.load.power"))


%% Every local controller passes on every generator
for cls = DebugScript.helper.model_classes("LocalController").Class'
    for key = generator_keys()
        [net, comp] = DebugScript.helper.build_3bus(key);
        con = attach_controller(comp, cls);
        DebugScript.helper.quiet(@() net.initialize);
        assert_contract(con, cls + " on " + key);
        assert_contract(comp, key + " with " + cls);
    end
end


%% Every local controller stays at the equilibrium in a simulation
for cls = DebugScript.helper.model_classes("LocalController").Class'
    [net, comp] = DebugScript.helper.build_3bus("gen-1axis");
    attach_controller(comp, cls);
    DebugScript.helper.quiet(@() net.initialize);
    sol = DebugScript.helper.quiet(@() net.simulate([0,1]));
    r = sol.odeResults.Bus(2).Component(1);
    assert(max(abs(r.X{:,:} - comp.rv_Xequilibrium'), [], "all") < 1e-6, cls)
end


%% AVR_DC1 with its default gain has a finite equilibrium
% 既定の kap = 0 では Vref = Inf になり simulate が止まる (known_failures に登録)
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
con = controller.avr.AVR_DC1("con");
comp.add_local_controller(con);
DebugScript.helper.quiet(@() net.initialize);
assert(all(isfinite(con.rv_Uequilibrium)), "Vref = %g", con.rv_Uequilibrium(1))


%% Every global controller works on the generators that have its inputs
for cls = DebugScript.helper.model_classes("GlobalController").Class'
    n_used = 0;
    for key = generator_keys()
        [net, comp] = DebugScript.helper.build_3bus(key);
        try
            net.add_global_controller(feval(cls, net, "gc", comp));   % (系統, タグ, 機器)
        catch ME
            assert(ME.identifier == "GUILDA:PowerNetwork:GconPorts", "%s on %s: %s", cls, key, ME.message);
            continue
        end
        n_used = n_used + 1;
        DebugScript.helper.quiet(@() net.initialize);
        gc = net.a_GlobalController{1};
        err = DebugScript.helper.jacobian_error(gc);
        assert(err < 1e-6, cls + " on " + key + ": Jacobian error " + err)
        assert_contract(comp, key + " with " + cls);
    end
    assert(n_used > 0, cls + " を接続できる発電機がない")
end


%% Every branch key works in the initialization
tab = DebugScript.helper.model_classes("Branch");
for k = 1:height(tab)
    net = PowerNetwork();
    net.add_bus("V", 1.0);
    net.add_bus();
    net.a_Bus{1}.add_component("gen-park");
    net.a_Bus{2}.add_component("load-power", "P", -0.5, "Q", -0.1);
    bra = net.add_branch(tab.Key(k), [1,2], "R", 0.01, "X", 0.1, "C", 0.01, "Tap", 0.98);
    assert(class(bra) == tab.Class(k) && bra.key == tab.Key(k), tab.Key(k))
    Y = bra.get_admittance_matrix();
    assert(isequal(size(Y), [2,2]) && all(isfinite(Y), "all"), tab.Key(k))
    DebugScript.helper.quiet(@() net.initialize);
    assert(abs(net.a_Bus{2}.c_Vequilibrium) > 0.5, tab.Key(k))
end


%% check_model_contract reports each kind of violation
check = @DebugScript.helper.check_model_contract;
assert(isempty(check(DebugScript.helper.BadComponentStub("none"))))
assert(contains(join(check(DebugScript.helper.BadComponentStub("xsize"))), "x, u sizes"))
assert(contains(join(check(DebugScript.helper.BadComponentStub("equilibrium"))), "dx:"))   % 契約には反しない
assert(contains(join(check(DebugScript.helper.BadComponentStub("currentreal"))), "I: NaN"))
assert(contains(join(check(DebugScript.helper.BadJacobianStub())), "Axx:"))
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(DebugScript.helper.BadControllerStub("jacobian"));
DebugScript.helper.quiet(@() net.initialize);
assert(contains(join(check(comp.a_LocalController{1})), "Axx:"))
sv = check(controller.avr.AVR_ST1("avr1"));   % 接続していないので validate が止まる
assert(contains(sv, "GUILDA:LocalController:ValidateNotAttached"))


%% validate keeps the existing fields and adds contract and inputs
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
flag = comp.validate(false);
fn = string(fieldnames(flag));
assert(all(ismember(["dx","I","Axx","Bxv","Bxi","Bxu","Cix","Div","Dii","Diu","Cyx","Dyv","Dyi","Dyu","contract","inputs"], fn)))


%% validate does not change the equilibrium
[net, comp] = DebugScript.helper.build_3bus("load-impedance");
DebugScript.helper.quiet(@() net.initialize);
x0 = comp.rv_Xequilibrium;  u0 = comp.rv_Uequilibrium;  Z0 = comp.Z;
comp.validate(false);
assert(isequal(comp.rv_Xequilibrium, x0) && isequal(comp.rv_Uequilibrium, u0))
assert(norm(comp.Z - Z0) < 1e-12)


%% Message prints without errors
[net, comp] = DebugScript.helper.build_3bus("gen-classical");
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
DebugScript.helper.quiet(@() net.initialize);
str = evalc("comp.validate();");
assert(contains(str, "Contract") && contains(str, "Connection source"))
str = evalc("comp.a_LocalController{1}.validate();");
assert(contains(str, "Contract") && contains(str, "Connection source"))


%% A correct stub passes
flag = DebugScript.helper.BadComponentStub("none").validate(false);
assert_no_fail(flag, "none");
assert(max(flag.dx.diff) < 1e-12 && max(flag.I.diff) < 1e-12)


%% Equilibrium error appears in the residual
flag = DebugScript.helper.BadComponentStub("equilibrium").validate(false);
assert_no_fail(flag, "equilibrium");    % 契約には反しない
assert(max(flag.dx.diff) > 0.05)


%% Wrong state size is detected
flag = DebugScript.helper.BadComponentStub("xsize").validate(false);
assert_only_fail(flag, "x, u sizes");
assert(contains(flag.contract{"x, u sizes","detail"}, "x 3 (sv_x 2)"))


%% fcn_I that is not a complex scalar is detected
flag = DebugScript.helper.BadComponentStub("currentreal").validate(false);
assert_only_fail(flag, "fcn_I complex scalar");
assert(all(isnan(flag.I.diff)))


%% fcn_Mass that uses the point is detected
flag = DebugScript.helper.BadComponentStub("massx").validate(false);
assert_only_fail(flag, "fcn_Mass constant and square");
assert(contains(flag.contract{"fcn_Mass constant and square","detail"}, "badsubscript"))


%% Required P, Q are valid
% 枠組みは常に get_equilibrium(V,I,P,Q) で呼ぶ
flag = DebugScript.helper.BadComponentStub("needpq").validate(false);
assert(all(flag.contract.status ~= "FAIL"))
assert(max(flag.dx.diff) < 1e-12)


%% Dependence on I is detected
flag = DebugScript.helper.BadComponentStub("currentdep").validate(false);
assert_only_fail(flag, "no dependence on I");
assert(abs(str2double(flag.contract{"no dependence on I","detail"}) - 1e-3) < 1e-6)


%% Wrong sizes of fcn_dx, fcn_Y and fcn_Mass are detected
flag = DebugScript.helper.BadComponentStub("dxsize").validate(false);
assert_only_fail(flag, "fcn_dx size");
assert(all(isnan(flag.dx.diff)))
flag = DebugScript.helper.BadComponentStub("ysize").validate(false);
assert_only_fail(flag, "fcn_Y size");
flag = DebugScript.helper.BadComponentStub("masssize").validate(false);
assert_only_fail(flag, "fcn_Mass constant and square");


%% Port names in sv_u are detected
flag = DebugScript.helper.BadPortStub().validate(false);
assert_only_fail(flag, "sv_u has no port names");


%% Analytic Jacobian errors are detected
flag = DebugScript.helper.BadJacobianStub().validate(false);
assert(max(flag.Axx{:,:}, [], "all") > 1)                       % 大きさの合う Axx は比べる
assert_only_fail(flag, "Jacobi_dx sizes");                      % Bxu が 2x3
assert(all(isnan(flag.Bxu{:,:}), "all"))


%% Controller under an AVR passes and inputs show the sources
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
DebugScript.helper.quiet(@() net.initialize);
avr = comp.a_LocalController{1};
pss = avr.a_LocalController{1};
flag = pss.validate(false);
assert_no_fail(flag, "pss");
assert_jacobians_close(flag, tol_jacobi, "pss");
assert(flag.inputs{"omega","source"} == "output of " + comp.str_tag)
flag = avr.validate(false);
assert_no_fail(flag, "avr");
assert(flag.inputs{"Vref","source"} == "equilibrium (not connected)")
assert(flag.inputs{"Vpss","source"} == "output of " + pss.str_tag)


%% Component inputs show the sources
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", comp.str_tag));
DebugScript.helper.quiet(@() net.initialize);
flag = comp.validate(false);
assert(flag.inputs{"Vfield","source"} == "output of " + comp.a_LocalController{1}.str_tag)
assert(contains(flag.inputs{"Pmech","source"}, "agc"))
flag = net.a_Bus{1}.a_Component{1}.validate(false);
assert(all(flag.inputs.source == "equilibrium (not connected)"))


%% A misspelled input name is visible in inputs
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(DebugScript.helper.BadControllerStub("none"));
DebugScript.helper.quiet(@() net.initialize);
flag = comp.a_LocalController{1}.validate(false);
assert_no_fail(flag, "none");
assert(flag.inputs{"Vppss","source"} == "equilibrium (not connected)")
assert(flag.inputs{"omega","source"} == "output of " + comp.str_tag)
assert(max(flag.Axx{:,:}, [], "all") < tol_jacobi)


%% Observed states and duplicate names are shown
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(DebugScript.helper.ObserveStub(["Xall";"Yall"]));
DebugScript.helper.quiet(@() net.initialize);
flag = comp.a_LocalController{1}.validate(false);
assert(height(flag.inputs) == numel(comp.sv_x) + numel(comp.sv_y))
assert(flag.inputs{"delta","source"} == "state of " + comp.str_tag)


%% Controller contract violations are detected
c_case = ["jacsize","Jacobi_dx sizes"; "massx","fcn_Mass constant and square"; "currentdep","no dependence on I"];
for k = 1:height(c_case)
    [net, comp] = DebugScript.helper.build_3bus("gen-1axis");
    comp.add_local_controller(DebugScript.helper.BadControllerStub(c_case(k,1)));
    DebugScript.helper.quiet(@() net.initialize);
    flag = comp.a_LocalController{1}.validate(false);
    assert_only_fail(flag, c_case(k,2));
end


%% A wrong controller state size is detected (initialize stops on it, so it is set afterwards)
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
con = DebugScript.helper.BadControllerStub("none");
comp.add_local_controller(con);
DebugScript.helper.quiet(@() net.initialize);
con.l_xsizeLater = true;
con.get_equilibrium(comp.c_Vequilibrium, comp.rv_Uequilibrium);
flag = con.validate(false);
assert_only_fail(flag, "x, u sizes");


%% Wrong controller Jacobian appears in the difference
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(DebugScript.helper.BadControllerStub("jacobian"));
DebugScript.helper.quiet(@() net.initialize);
flag = comp.a_LocalController{1}.validate(false);
assert(abs(flag.Axx{1,1} - 5) < 1e-8)


%% Controller that is not attached stops with a clear error
con = controller.avr.AVR_ST1("avr1");
assert_error(@() con.validate(false), "GUILDA:LocalController:ValidateNotAttached");


%% Controller without an equilibrium asks for initialize
[~, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
assert_error(@() comp.a_LocalController{1}.validate(false), "GUILDA:PowerNetwork:EquilibriumStale");


function assert_contract(obj, str_name)
    sv = DebugScript.helper.check_model_contract(obj);
    assert(isempty(sv), "%s: %s", str_name, join(sv, ", "));
end

function con = attach_controller(comp, cls)
    % 新しいクラスのコンストラクタも (タグ) で呼べる必要がある
    c_arg = {};
    if cls == "controller.avr.AVR_DC1"   % 既定の kap = 0 は別のテストで確認している
        c_arg = {"kap", 20};
    end
    con = feval(cls, "con", c_arg{:});
    if con.key == "pss"
        comp.add_local_controller(controller.avr.AVR_ST1("avr"), con);
    else
        comp.add_local_controller(con);
    end
end

function sv_key = generator_keys()
    tab = DebugScript.helper.model_classes("Component");
    sv_key = tab.Key(arrayfun(@(c) ismember("component.generator.abstract", superclasses(c)), tab.Class))';
end

function sv_key = generated_keys(str_class, str_file)
    % 生成された switch の case ('key'; mkInst = ...) を読む
    str = fileread(fullfile(GUILDA.pwd, "_GUILDAsystem", str_class, str_file), "Encoding", "UTF-8");
    sv_key = reshape(string(extractBetween(str, "case '", "';")), [], 1);
end

function assert_no_fail(flag, str_name)
    lv = flag.contract.status == "FAIL";
    assert(~any(lv), "%s: %s", str_name, join(flag.contract.Properties.RowNames(lv) + " (" + flag.contract.detail(lv) + ")", ", "));
end

function assert_only_fail(flag, str_check)
    sv = string(flag.contract.Properties.RowNames(flag.contract.status == "FAIL"));
    assert(isequal(sv, str_check), "FAIL: %s (expected %s)", join(sv,", "), str_check);
end

function assert_jacobians_close(flag, tol, str_name)
    for fn = ["Axx","Bxv","Bxi","Bxu","Cix","Div","Dii","Diu","Cyx","Dyv","Dyi","Dyu"]
        if isfield(flag, fn) && ~isempty(flag.(fn)) && width(flag.(fn)) > 0
            r = max(flag.(fn){:,:}, [], "all");
            assert(r < tol, "%s: %s %g", str_name, fn, r);
        end
    end
end

function assert_error(f, str_id)
    try
        f();
    catch ME
        assert(ME.identifier == str_id, "%s", ME.identifier);
        return
    end
    error("no error (expected %s)", str_id);
end
