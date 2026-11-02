% F22 モデルの契約の検査 (comp.validate, con.validate)
%
% 組み込みモデルは FAIL 0、不正モデルは該当する検査が FAIL になることを確認する。
%
% 実行: runtests("DebugScript.test_F22_model_contract")  または  DebugScript.run_all("Features","F22")

% 共通設定 (各テストの前に毎回実行される)
c_keys = ["gen-classical","gen-1axis","gen-2axis","gen-park","gen-droop","load-power","load-impedance"];
tol_jacobi = 1e-5;


%% Built-in components pass at the equilibrium
for key = c_keys
    [net, comp] = DebugScript.helper.build_3bus(key);
    DebugScript.helper.quiet(@() net.initialize);
    flag = comp.validate(false);
    assert_no_fail(flag, key);
    assert(isempty(flag.dx) || max(flag.dx.diff) < 1e-8, key + ": dx");
    assert(max(flag.I.diff) < 1e-8, key + ": I");
    assert_jacobians_close(flag, tol_jacobi, key);
end


%% Built-in components pass at a random point without an equilibrium
for key = c_keys
    [~, comp] = DebugScript.helper.build_3bus(key);
    flag = comp.validate(false);
    assert_no_fail(flag, key);
    assert(isempty(flag.dx) || max(flag.dx.diff) < 1e-8, key + ": dx");   % V, I の取り違えがない
    assert(max(flag.I.diff) < 1e-8, key + ": I");
    assert_jacobians_close(flag, tol_jacobi, key);
end


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


%% Built-in controllers pass
c_con = {@() controller.avr.AVR_ST1("avr1"), @() controller.avr.AVR_DC1("avr1"), @() controller.local_LQR("lqr1")};
for k = 1:numel(c_con)
    [net, comp] = DebugScript.helper.build_3bus("gen-1axis");
    comp.add_local_controller(c_con{k}());
    DebugScript.helper.quiet(@() net.initialize);
    con = comp.a_LocalController{1};
    flag = con.validate(false);
    assert_no_fail(flag, con.str_tag);
    assert(isempty(flag.dx) || max(flag.dx.diff) < 1e-8, con.str_tag + ": dx");
    assert_jacobians_close(flag, tol_jacobi, con.str_tag);
end


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
