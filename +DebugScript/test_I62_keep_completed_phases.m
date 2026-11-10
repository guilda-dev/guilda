% I62 区間を解けないときに完了済みの区間を残す
%
%   数値的な失敗 : flag = -1 と部分結果を返し、エラーは output.exception に残る
%   利用者の関数 : 入力関数などのエラーは今までどおり例外になる
%
% 実行: runtests("DebugScript.test_I62_keep_completed_phases")  または  DebugScript.run_all("Features","I62")

% 共通設定 (実行は 1 度だけで、net は全テストで共有される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);

sv_gen = generators(net);
ev_trip_later = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.5], "TripUnit", sv_gen);
ev_trip_first = DebugScript.helper.scenario("trip", net, "TimeSpan", [0,1.5], "TripUnit", sv_gen);
ev_nan = DebugScript.helper.scenario("nan", net, "TimeSpan", [1,1.2], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", NaN);
s_warn = "GUILDA:PowerNetwork:SimulationIncomplete";


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Solver error in a later phase keeps the completed phases
[sol, flag, output] = run(net, [0,2], ev_trip_later);
assert(flag == -1)
assert(output.tEnd == 1 && sol.rv_t(end) == 1)
assert(output.nPhases == 3 && output.nPhasesDone == 1)
assert(~sol.l_success)
ref = run(net, [0,1]);
assert(isequaln(sol.rv_t, ref.rv_t) && isequaln(sol.rm_variable, ref.rm_variable))


%% Exception of the phase is kept in output
[~, ~, output] = run(net, [0,2], ev_trip_later);
ME = output.exception;
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "phase 2") && contains(ME.message, "t = [1, 1.5]"), ME.message)
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:ode15s:MassMatrixAllZero", DebugScript.helper.msg_id(ME.cause{1}))


%% Warning and message name the reason
lastwarn("");
[~, ~, output] = run(net, [0,2], ev_trip_later);
[s_msg, id] = lastwarn(); id = DebugScript.helper.msg_id(s_msg, id);
assert(id == s_warn, id)
assert(contains(s_msg, output.message))
assert(contains(output.message, "t = 1 s of 2 s") && contains(output.message, output.exception.message), output.message)


%% Failed initial condition returns the completed phases
[sol, flag, output] = run(net, [0,2], ev_nan);
assert(flag == -1)
assert(output.tEnd == 1 && sol.rv_t(end) == 1 && output.nPhasesDone == 1)
ME = output.exception;
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:InitialConditionFailed", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "phase 2") && contains(ME.message, "t = [1, 1.2]"), ME.message)
assert(DebugScript.helper.msg_id(ME.cause{1}) == "GUILDA:SolverODE:AlgebraicNotSolved", DebugScript.helper.msg_id(ME.cause{1}))


%% First phase failure returns an empty result
[sol, flag, output] = run(net, [0,2], ev_trip_first);
assert(flag == -1)
assert(output.tEnd == 0 && output.nPhasesDone == 0)
assert(isempty(sol.rv_t) && size(sol.rm_variable,1) == 0 && width(sol.rm_variable) == height(sol.tab_variable))
assert(isempty(sol.odeResults.t) && height(sol.odeResults.Bus(1).V) == 0)
assert(contains(output.message, "phase 1"), output.message)
expect_error(@() sol.get_point(0), "GUILDA:ResultODE:PointTime")


%% Empty result can be plotted
sol = run(net, [0,2], ev_trip_first);
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
ax = sol.Plot(Parent=fig);
assert(isgraphics(ax))
ax = sol.Plot(Parent=fig, Quantity="omega");
assert(isgraphics(ax))


%% Empty result can be exported
sol = run(net, [0,2], ev_trip_first);
s_dir = tempname;
mkdir(s_dir);
c_dir = onCleanup(@() rmdir(s_dir, "s"));
s_csv = fullfile(s_dir, "empty.csv");
sol.Export(s_csv);
tab = readtable(s_csv);
assert(height(tab) == 0 && any(string(tab.Properties.VariableNames) == "t"))
s_mat = fullfile(s_dir, "empty.mat");
sol.Export(s_mat);
s = load(s_mat);
assert(s.flag == -1 && DebugScript.helper.msg_id(s.output.exception) == "GUILDA:SolverODE:PhaseFailed")


%% Export option works when the first phase fails
s_dir = tempname;
mkdir(s_dir);
c_dir = onCleanup(@() rmdir(s_dir, "s"));
s_csv = fullfile(s_dir, "opt.csv");
[~, flag] = run(net, [0,2], ev_trip_first, "Export", s_csv);
close all
assert(flag == -1 && isfile(s_csv))


%% Working data is restored after a failed phase
run(net, [0,2], ev_trip_later);
for i = 1:numel(net.a_Bus)
    for j = 1:numel(net.a_Bus{i}.a_Component)
        comp = net.a_Bus{i}.a_Component{j};
        assert(get_private(comp, "l_isConnect"), comp.s_tag)
    end
end
ref = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() ref.initialize);

sol = run(net, [0,1]);
sol_ref = run(ref, [0,1]);
assert(isequaln(sol.rm_variable, sol_ref.rm_variable))


%% Input function error is still raised
ev = DebugScript.helper.scenario("in", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) boom(t));
ME = catch_error(@() run(net, [0,4], ev));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "phase 2") && DebugScript.helper.msg_id(ME.cause{1}) == "DebugScript:boom")


%% Input function error with a MATLAB identifier is still raised
ev = DebugScript.helper.scenario("in", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) bad_index(t));
ME = catch_error(@() run(net, [0,4], ev));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:badsubscript", DebugScript.helper.msg_id(ME.cause{1}))


%% Solver error of an input function is still raised
ev = DebugScript.helper.scenario("in", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) own_solver(t));
ME = catch_error(@() run(net, [0,4], ev));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:ode15s:MassMatrixAllZero", DebugScript.helper.msg_id(ME.cause{1}))


%% Wrong solver settings are still raised
net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);

ME = catch_error(@() run(net2, [0,1], "SolverOptions", matlab.ode.options.ODE45));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:SolverODE:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:ode45:MassSingularYes", DebugScript.helper.msg_id(ME.cause{1}))


%% Convergence failure of the initial condition returns the completed phases
ev = DebugScript.helper.scenario("huge", net, "TimeSpan", [1,1.2], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", 1e6);
[~, flag, output] = run(net, [0,2], ev);
assert(flag == -1 && output.tEnd == 1)
assert(DebugScript.helper.msg_id(output.exception.cause{1}) == "GUILDA:SolverODE:AlgebraicNotSolved", DebugScript.helper.msg_id(output.exception.cause{1}))


%% Solver error with ode23t returns the completed phases
[~, flag, output] = run(net, [0,2], ev_trip_later, "SolverOptions", matlab.ode.options.ODE23t, "Solver", "ode23t");
assert(flag == -1 && output.tEnd == 1)
assert(DebugScript.helper.msg_id(output.exception.cause{1}) == "MATLAB:ode23t:MassMatrixAllZero", DebugScript.helper.msg_id(output.exception.cause{1}))


function varargout = run(net, varargin)
    w = warning("off", "GUILDA:PowerNetwork:SimulationIncomplete");
    c = onCleanup(@() warning(w));
    [varargout{1:max(nargout,1)}] = net.simulate(varargin{:});
end

function ME = catch_error(fcn)
    ME = [];
    try
        fcn();
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end

function expect_error(fcn, s_id)
    ME = catch_error(fcn);
    assert(DebugScript.helper.msg_id(ME) == s_id, DebugScript.helper.msg_id(ME))
end

function sv = generators(net)
    sv = strings(0,1);
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            comp = net.a_Bus{i}.a_Component{j};
            if startsWith(comp.s_tag, "SG")
                sv(end+1,1) = comp.s_tag; %#ok<AGROW>
            end
        end
    end
end

function u = boom(t)
    if t > 0.5
        error("DebugScript:boom", "boom at t = %g", t)
    end
    u = 0;
end

function u = bad_index(t)
    u = 0;
    if t > 0.5
        v = 1:2;
        u = v(0);
    end
end

function u = own_solver(t)
    u = 0;
    if t > 0.5
        ode15s(@(s,x) -x, [0,1], 1, odeset("Mass", 0));
    end
end

function v = get_private(obj, str)
    w = warning("off", "MATLAB:structOnObject");
    c = onCleanup(@() warning(w));
    s = builtin("struct", obj);      % struct はオーバーロードされている
    v = s.(str);
end
