% Issue 105: モデルへの暗黙の要求を宣言し、枠組みの呼び方を一通りにする
%
% get_equilibrium は常に 4 引数で呼ぶ。fcn_Mass は定数でなければ simulate が案内つきで止まる。
% getCompPQ は UseInternalState=true のときだけ必要で、無ければ案内つきで止まる。
%
% 実行: runtests("DebugScript.test_I105_model_contracts")  または  DebugScript.run_all("Features","I105")


%% Trip of a generator that requires P and Q completes
% スタブをキーとして一時的に登録するので、GUILDA の再実行が 1 回で済むようにまとめる
c_stub = register_stubs();

net = DebugScript.helper.build_3bus("gen-1axis");
net.a_Bus{3}.add_component("gen-needpq-stub");
DebugScript.helper.quiet(@() net.initialize);
s_tag = net.a_Bus{3}.a_Component{end}.s_tag;
ev = DebugScript.helper.scenario("trip", net, "TimeSpan", [0.2,0.4], "TripUnit", s_tag);
sol = DebugScript.helper.quiet(@() net.simulate([0,1], ev));
assert(sol.flag == 1, sol.output.message)

% fcn_Mass of a component that uses x stops with the tag
net = DebugScript.helper.build_3bus("gen-1axis");
net.a_Bus{3}.add_component("test-bad-stub", "parameter","massx");
DebugScript.helper.quiet(@() net.initialize);
check_mass_error(net, net.a_Bus{3}.a_Component{end}.s_tag);

% get_sys keeps its point, so the contract concerns simulate only
assert(~isempty(DebugScript.helper.quiet(@() net.a_Bus{3}.a_Component{end}.get_sys())))


%% fcn_Mass of a local controller that uses x stops with the tag
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
con = DebugScript.helper.BadControllerStub("massx");
comp.add_local_controller(con);
DebugScript.helper.quiet(@() net.initialize);
check_mass_error(net, con.s_tag);


%% UseInternalState names the component without getCompPQ
for s_key = ["gen-droop","load-impedance"]
    net = DebugScript.helper.build_3bus("gen-1axis");
    net.a_Bus{3}.add_component(s_key);
    DebugScript.helper.quiet(@() net.initialize);
    s_tag = net.a_Bus{3}.a_Component{end}.s_tag;
    ME = [];
    try
        DebugScript.helper.quiet(@() net.calculate_continuation_powerflow( ...
            LoadBus=net.a_Bus{3}.s_tag, UseInternalState=true));
    catch ME
    end
    assert(~isempty(ME), s_key + " did not stop")
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:build_layout:MissingGetCompPQ", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, s_tag), ME.message)
end


%% Controllers declare get_equilibrium
for s_class = ["LocalController","GlobalController"]
    mc = meta.class.fromName(s_class);
    m = mc.MethodList(strcmp({mc.MethodList.Name}, "get_equilibrium"));
    assert(isscalar(m) && m.Abstract && ~m.Static, s_class)
end


%% Declarations match the calls of the framework
for c_decl = {"Component","fcn_dx"; "LocalController","fcn_dx"; "LocalController","fcn_Mass"; "controller.pss.PSS1","fcn_Mass"}.'
    mc = meta.class.fromName(c_decl{1});
    m = mc.MethodList(strcmp({mc.MethodList.Name}, c_decl{2}));
    c_in = m.InputNames;
    if isequal(c_in, {'varargin'})
        % メソッドファイルに arguments ブロックがあると meta は varargin を返すので、関数行から読む
        str = fileread(fullfile(fileparts(which(c_decl{1})), c_decl{2} + ".m"));
        c_tok = regexp(str, 'function[^(]*\(([^)]*)\)', 'tokens', 'once');
        c_in = cellstr(strtrim(split(string(c_tok{1}), ",")));
    end
    assert(isequal(c_in(1:2), {'t';'x'}) || isequal(c_in(1:2), {'r_t';'rv_x'}), c_decl{1})
end


function check_mass_error(net, s_tag)
    ME = [];
    try
        DebugScript.helper.quiet(@() net.simulate([0,1]));
    catch ME
    end
    assert(~isempty(ME), "simulate did not stop")
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:read_mass:NotConstant", DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, s_tag), ME.message)
end

function c = register_stubs()
% +DebugScript のクラスは add_component のキーにならないので、写しを登録する
    s_dir   = fileparts(fileparts(which("component.load.power")));
    s_gen   = fullfile(fileparts(s_dir), "+generator", "needpq_i105_stub.m");
    str = fileread(which("DebugScript.helper.NeedPQGeneratorStub"));
    str = replace(str, "classdef NeedPQGeneratorStub", "classdef needpq_i105_stub");
    writelines(str, s_gen);

    s_load = fullfile(s_dir, "bad_i105_stub.m");
    str = fileread(which("DebugScript.helper.BadComponentStub"));
    str = replace(str, "DebugScript.helper.BadComponentStub", "component.load.bad_i105_stub");
    str = replace(str, "classdef BadComponentStub", "classdef bad_i105_stub");
    str = replace(str, "BadComponentStub(s_bad, s_tag, opt)", "bad_i105_stub(s_tag, s_bad, opt)");
    str = regexprep(str, '(\n\s+)s_bad(\s+%[^\n]*)(\n\s+)s_tag = "1"(\s+%[^\n]*)', '$1s_tag$4$3s_bad$2');
    writelines(str, s_load);

    rehash
    evalc("GUILDA;");
    c = onCleanup(@() unregister_stubs(s_gen, s_load));
end

function unregister_stubs(s_gen, s_load)
    delete(s_gen);
    delete(s_load);
    rehash
    evalc("GUILDA;");
end
