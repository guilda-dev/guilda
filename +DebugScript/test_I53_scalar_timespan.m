% I53 長さのない TimeSpan (ODEevent)
%
% fault, trip, input のスカラーや [t,t] は、無関係なイベントで継続時間が変わらないようエラーにする。
% offset と効果のないイベントは、これまでどおり 1 つの時刻で指定できることを確認する。
%
% 実行: runtests("DebugScript.test_I53_scalar_timespan")  または  DebugScript.run_all("Features","I53")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
c_fault = {"FaultBus", "B008"};
c_trip  = {"TripUnit", "LPQ2B003"};
c_input = {"InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.01};
c_os    = {"OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 1e-3};


%% Fault, trip and input need a duration
for c_kind = {c_fault, c_trip, c_input}
    expect_zero_length(net, "1", "TimeSpan", 1, c_kind{1}{:});
    expect_zero_length(net, "[1 1]", "TimeSpan", [1,1], c_kind{1}{:});
end


%% Unrelated event does not decide the duration (Issue の再現手順)
ev_fault = ODEevent("fault", net, "TimeSpan", 1, c_fault{:});
ev_other = ODEevent("other", net, "TimeSpan", [1.5,2], c_trip{:});
assert(event_error(net, ev_fault) == "GUILDA:ODEevent:ZeroLengthTimeSpan")
assert(event_error(net, ev_fault, ev_other) == "GUILDA:ODEevent:ZeroLengthTimeSpan")


%% An offset with a fault in one event still needs a duration
expect_zero_length(net, "1", "TimeSpan", 1, c_os{:}, c_fault{:});


%% TimeSpan changed after the event was created
ev = ODEevent("ev", net, "TimeSpan", [1,1.05], c_fault{:});
ev.TimeSpan = 1;
assert(event_error(net, ev) == "GUILDA:ODEevent:ZeroLengthTimeSpan")


%% Offset and an event without effect keep a single time
for ts = {0, 1, [1,1], [1,2]}
    [sol, flag] = net.simulate([0,3], ODEevent("os", net, "TimeSpan", ts{1}, c_os{:}));
    assert(flag == 1 && sol.odeResults.t(end) == 3)
end
for ts = {1, [1,1]}
    [sol, flag] = net.simulate([0,3], ODEevent("none", net, "TimeSpan", ts{1}));
    assert(flag == 1 && sol.odeResults.t(end) == 3)
end


%% Events with a duration still run
for c_kind = {c_fault, c_trip, c_input}
    [sol, flag] = net.simulate([0,2], ODEevent("ev", net, "TimeSpan", [1,1.05], c_kind{1}{:}));
    assert(flag == 1 && sol.odeResults.t(end) == 2)
end


function expect_zero_length(net, str_ts, varargin)
    % エラーの ID と、メッセージが原因と対処を示すことを確認する
    ev = ODEevent("ev", net, varargin{:});
    [str_id, str_msg] = event_error(net, ev);
    assert(str_id == "GUILDA:ODEevent:ZeroLengthTimeSpan", str_id + ": " + str_msg)
    assert(all(contains(str_msg, ['"ev"', str_ts, "[t_start, t_end]"])), "原因が示されない: " + str_msg)
end

function [str_id, str_msg] = event_error(net, varargin)
    str_id  = "";
    str_msg = "";
    try
        net.simulate([0,3], varargin{:});
    catch ME
        str_id  = string(ME.identifier);
        str_msg = string(ME.message);
    end
end
