% I67 replace_component の局所制御器の扱い (Issue #67)
%
%   既定では制御器を新しい機器へ渡さず GUILDA:Bus:ControllersDropped で警告する
%   Controllers="keep" で引き継ぎ、引き継げない置換は GUILDA:Bus:ControllersNotKept で何も変更しない
%
% 実行: runtests("DebugScript.test_I67_replace_controllers")  または  DebugScript.run_all("Features","I67")

%% The default drops the controllers with a warning naming them
[net, bus, gen, avr, pss] = network_with_avr_pss();
[new, id, str] = replace_warned(@() bus.replace_component(gen.s_tag, "gen-1axis"));
assert(id == "GUILDA:Bus:ControllersDropped")
assert(contains(str, avr.s_tag) && contains(str, pss.s_tag) && contains(str, gen.s_tag))
assert(isempty(new.a_LocalController))
assert(bus.a_Component{1} == new)


%% The default leaves the controllers on the replaced component
[net, bus, gen, avr, pss] = network_with_avr_pss();
replace_warned(@() bus.replace_component(gen.s_tag, "gen-1axis"));
assert(gen.a_LocalController{1} == avr && avr.a_Component == gen)
assert(avr.a_LocalController{1} == pss && pss.a_Component == avr)


%% A component without controllers is replaced without a warning
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
assert(isempty(gen.a_LocalController))
[new, id] = replace_warned(@() net.a_Bus{1}.replace_component(gen.s_tag, "gen-1axis"));
assert(id == "")
assert(isempty(new.a_LocalController))


%% "keep" with the optional parameter omitted moves the AVR and the PSS
[net, bus, gen, avr, pss] = network_with_avr_pss();
[new, id] = replace_warned(@() bus.replace_component(gen.s_tag, "gen-1axis", Controllers="keep"));
assert(id == "")
assert(new.a_LocalController{1} == avr && avr.a_Component == new)
assert(avr.a_LocalController{1} == pss && pss.a_Component == avr)
assert(isempty(gen.a_LocalController))


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
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.flag == 1)


%% A kept LQR follows the states of the new component
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{1}.a_Component{1};
lqr = controller.local_LQR("lqrA", Input="Vfield");
gen.add_local_controller(lqr);
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
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", comp.s_tag));
ME = caught(@() net.a_Bus{2}.replace_component(comp.s_tag, "gen-1axis", Controllers="keep"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:ComponentControlled")
assert(net.a_Bus{2}.a_Component{1} == comp)


function [net, bus, gen, avr, pss] = network_with_avr_pss()
    % A generator with an AVR and a PSS, replaced in each test
    net = DebugScript.helper.build_ieee14();
    bus = net.a_Bus{1};
    gen = bus.a_Component{1};
    avr = controller.avr.AVR_ST1("avrA");
    pss = controller.pss.PSS1("pssA");
    gen.add_local_controller(avr, pss);
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
