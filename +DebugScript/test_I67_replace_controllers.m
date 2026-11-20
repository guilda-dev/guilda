% I67 replace_component のローカル制御器の扱い (Issue #67)
%
%   既定では制御器を新しい機器へ渡さず、置き換えた機器ごと削除して GUILDA:Bus:ControllersDropped で警告する
%   Controllers="keep" で引き継ぎ、引き継げない置換は GUILDA:Bus:ControllersNotKept で何も変更しない
%
% 実行: runtests("DebugScript.test_I67_replace_controllers")  または  DebugScript.run_all("Features","I67")

c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% The default drops the controllers with a warning naming them
[net, bus, gen, avr, pss] = network_with_avr_pss();
sv_tag = [gen.s_tag, avr.s_tag, pss.s_tag];
[new, id, str] = replace_warned(@() bus.replace_component(gen.s_tag, "gen-1axis"));
assert(id == "GUILDA:Bus:ControllersDropped")
assert(all(contains(str, sv_tag)))
assert(~any(contains(str, sv_tag(1) + "CG")))    % 既定の Static の調速機は名前を出さない
% 新しい発電機は自分の既定の Static の AVR と調速機を持つ
assert(isequal(cellfun(@(c) c.key, new.a_LocalController), ["avr-static"; "gov-static"]))
assert(bus.a_Component{1} == new)


%% The default deletes the controllers with the replaced component
[net, bus, gen, avr, pss] = network_with_avr_pss();
replace_warned(@() bus.replace_component(gen.s_tag, "gen-1axis"));
assert(~isvalid(gen) && ~isvalid(avr) && ~isvalid(pss))


%% A component with only the default Static controllers is replaced without a warning
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
assert(isequal(cellfun(@(c) c.key, gen.a_LocalController), ["avr-static"; "gov-static"]))
[new, id] = replace_warned(@() net.a_Bus{1}.replace_component(gen.s_tag, "gen-1axis"));
assert(id == "")
assert(isequal(cellfun(@(c) c.key, new.a_LocalController), ["avr-static"; "gov-static"]))
% "keep" も警告せず、新しい発電機は自分の Static を持ち、負荷へ置き換えるときも止まらない
gen = new;
[new, id] = replace_warned(@() net.a_Bus{1}.replace_component(gen.s_tag, "gen-park", Controllers="keep"));
assert(id == "" && ~isvalid(gen) && isequal(cellfun(@(c) c.key, new.a_LocalController), ["avr-static"; "gov-static"]))
assert(all(cellfun(@(c) c.a_Component == new, new.a_LocalController)))
gen = new;
[new, id] = replace_warned(@() net.a_Bus{1}.replace_component(gen.s_tag, "load-impedance", Controllers="keep"));
assert(id == "" && isempty(new.a_LocalController))


%% A generator with the default Static controllers is replaced before the first initialize
% 平衡点がまだない機器の置換では、新しい機器も平衡点なし (追加した直後と同じ) になり、その後 initialize できる
for s_key = ["gen-1axis", "gen-park"]
    net = PowerNetwork("T");
    bus = net.add_bus();
    gen = bus.add_component("gen-classical");
    bus.l_isSlack = true;
    net.add_bus().add_component("load-power");
    net.add_branch("pi", [1,2], X=0.1);
    assert(isempty(gen.c_Iequilibrium))
    new = bus.replace_component(gen.s_tag, s_key);
    assert(isempty(new.c_Iequilibrium) && isempty(new.rv_Uequilibrium))
    assert(isequal(cellfun(@(c) c.key, new.a_LocalController), ["avr-static"; "gov-static"]))
    DebugScript.helper.quiet(@() net.initialize);
    assert(~isempty(new.c_Iequilibrium) && numel(new.rv_Uequilibrium) == numel(new.sv_u))
end


%% "keep" with the optional parameter omitted moves the AVR and the PSS
[net, bus, gen, avr, pss] = network_with_avr_pss();
[new, id] = replace_warned(@() bus.replace_component(gen.s_tag, "gen-1axis", Controllers="keep"));
assert(id == "")
assert(new.a_LocalController{1} == avr && avr.a_Component == new)
assert(avr.a_LocalController{1} == pss && pss.a_Component == avr)
assert(~isvalid(gen))


%% "keep" with the parameter given uses that parameter
[net, bus, gen, avr] = network_with_avr_pss();
new = bus.replace_component(gen.s_tag, "gen-1axis", nan, Controllers="keep");
assert(new.a_LocalController{1} == avr)


%% A kept AVR and PSS are simulated after net.initialize
[net, bus, gen] = network_with_avr_pss();
n_x = numel(gen.a_LocalController{1}.sv_x) + numel(gen.a_LocalController{1}.a_LocalController{1}.sv_x);
new = bus.replace_component(gen.s_tag, "gen-1axis", Controllers="keep");
assert(DebugScript.helper.is_stale(net))
DebugScript.helper.quiet(@() net.initialize);
assert(numel(new.rv_Xequilibrium_all) == numel(new.sv_x) + n_x)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,1]).s_tag, Time=[0,1]);
assert(sol.flag == 1)


%% A kept LQR follows the states of the new component
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
lqr = gen.add_local_controller("local-LQR", parameter=struct(Input="Vfield"));
DebugScript.helper.quiet(@() net.initialize);
new = net.a_Bus{1}.replace_component(gen.s_tag, "gen-classical", Controllers="keep");
assert(new.a_LocalController{1} == lqr && lqr.a_Component == new)
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(size(lqr.K), [1, numel(new.sv_x)]))


%% "keep" onto a load is rejected and changes nothing
[net, bus, gen, avr, pss] = network_with_avr_pss();
DebugScript.helper.quiet(@() net.initialize);
sv_log = DebugScript.helper.stale(net);
ME = caught(@() bus.replace_component(gen.s_tag, "load-power", Controllers="keep"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:ControllersNotKept")
assert(contains(ME.message, "Vfield") && contains(ME.message, avr.s_tag))
assert_unchanged(net, bus, gen, avr, pss, sv_log)


%% "keep" is rejected when the new component lacks an observed signal
[net, bus, gen, avr, pss] = network_with_avr_pss();
DebugScript.helper.quiet(@() net.initialize);
sv_log = DebugScript.helper.stale(net);
ME = caught(@() bus.replace_component(gen.s_tag, "gen-droop", Controllers="keep"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:ControllersNotKept")
assert(contains(ME.message, "omega") && contains(ME.message, pss.s_tag))
assert_unchanged(net, bus, gen, avr, pss, sv_log)


%% An unknown value of Controllers is an error
[net, bus, gen] = network_with_avr_pss();
caught(@() bus.replace_component(gen.s_tag, "gen-1axis", Controllers="move"));
assert(bus.a_Component{1} == gen)


%% A component under a global controller is still rejected, also with "keep"
net  = DebugScript.helper.build_ieee14();
comp = net.a_Bus{2}.a_Component{1};
net.add_global_controller("agc-PI", comp.s_tag);
ME = caught(@() net.a_Bus{2}.replace_component(comp.s_tag, "gen-1axis", Controllers="keep"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:ComponentControlled")
assert(net.a_Bus{2}.a_Component{1} == comp)


%% The default names a PSS under the Static AVR in the warning
[net, bus, gen, pss] = network_with_static_pss("pss-PSS1");
sv_tag = [pss.s_tag, gen.avr.s_tag];
[new, id, str] = replace_warned(@() bus.replace_component(gen.s_tag, "gen-1axis"));
assert(id == "GUILDA:Bus:ControllersDropped" && contains(str, sv_tag(1)))
assert(~contains(str, sv_tag(2)))    % 既定の Static の AVR は名前を出さない
assert(isempty(new.pss) && new.avr.key == "avr-static" && ~isvalid(pss))


%% "keep" moves a PSS under the Static AVR to the Static AVR of the new generator
[net, bus, gen, pss] = network_with_static_pss("pss-PSS1");
avr_pre = gen.avr;
[new, id] = replace_warned(@() bus.replace_component(gen.s_tag, "gen-park", Controllers="keep"));
assert(id == "" && ~isvalid(gen) && ~isvalid(avr_pre))
assert(new.avr.key == "avr-static" && new.avr ~= avr_pre && new.pss == pss && pss.a_Component == new.avr)
assert(isequal(cellfun(@(c) c.key, new.a_LocalController), ["avr-static"; "gov-static"]))
assert(DebugScript.helper.is_stale(net))
DebugScript.helper.quiet(@() net.initialize);
assert(numel(new.rv_Xequilibrium_all) == numel(new.sv_x) + numel(pss.sv_x))
sol = net.simulate(DebugScript.helper.noop_event(net,[0,1]).s_tag, Time=[0,1]);
assert(sol.flag == 1)


%% "keep" moves Retrofit under the Static AVR and it follows the states of the new generator
[net, bus, gen, pss] = network_with_static_pss("pss-retrofit");
new = bus.replace_component(gen.s_tag, "gen-park", Controllers="keep");
assert(new.pss == pss && pss.a_Component == new.avr && isa(new.avr, "controller.avr.Static"))
assert(isequal(pss.sv_u, new.sv_x(:)))
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(size(pss.K), [1, numel(new.sv_x)]))
sol = net.simulate(DebugScript.helper.noop_event(net,[0,1]).s_tag, Time=[0,1]);
assert(sol.flag == 1)


%% "keep" of a PSS under the Static AVR is rejected and changes nothing when it does not fit
% 観測する omega がない発電機と、AVR の枠がない負荷
for s_key = ["gen-droop", "load-power"]
    [net, bus, gen, pss] = network_with_static_pss("pss-PSS1");
    avr = gen.avr;
    DebugScript.helper.quiet(@() net.initialize);
    sv_log = DebugScript.helper.stale(net);
    ME = caught(@() bus.replace_component(gen.s_tag, s_key, Controllers="keep"));
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:ControllersNotKept" && contains(ME.message, pss.s_tag))
    assert(bus.a_Component{1} == gen && gen.avr == avr && gen.pss == pss && pss.a_Component == avr)
    assert(~DebugScript.helper.is_stale(net) && isequal(DebugScript.helper.stale(net), sv_log))
end


function [net, bus, gen, pss] = network_with_static_pss(s_key)
    % A generator with a PSS under its default Static AVR
    net = DebugScript.helper.build_ieee14();
    bus = net.a_Bus{1};
    gen = bus.a_Component{1};
    assert(gen.avr.key == "avr-static")
    pss = gen.add_local_controller(s_key);
end

function [net, bus, gen, avr, pss] = network_with_avr_pss()
    % A generator with an AVR and a PSS, replaced in each test
    net = DebugScript.helper.build_ieee14();
    bus = net.a_Bus{1};
    gen = bus.a_Component{1};
    avr = gen.add_local_controller("avr-ST1");
    pss = gen.add_local_controller("pss-PSS1");
end

function assert_unchanged(net, bus, gen, avr, pss, sv_log)
    assert(bus.a_Component{1} == gen && gen.a_Bus == bus)
    assert(gen.a_LocalController{1} == avr && avr.a_Component == gen)
    assert(avr.a_LocalController{1} == pss && pss.a_Component == avr)
    assert(~DebugScript.helper.is_stale(net) && isequal(DebugScript.helper.stale(net), sv_log))
end

function [new, id, str] = replace_warned(fcn)
    % Run a replacement and return its last warning ("" without one)
    lastwarn("", "");
    new = fcn();
    [str, id] = lastwarn(); id = DebugScript.helper.msg_id(str, id);
    str = string(str);
    id  = string(id);
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
