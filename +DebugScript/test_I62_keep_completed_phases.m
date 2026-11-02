% I62 区間を解けないときに完了済みの区間を残す
%
%   数値的な失敗 : flag = -1 と部分結果を返し、エラーは output.exception に残る
%   利用者の関数 : 入力関数などのエラーは今までどおり例外になる
%
% 実行: runtests("DebugScript.test_I62_keep_completed_phases")  または  DebugScript.run_all("Features","I62")

% 共通設定 (実行は 1 度だけで、net は全テストで共有される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
net.solver_ODE.Progress = "none";
sv_gen = generators(net);
ev_trip_later = ODEevent("trip", net, "TimeSpan", [1,1.5], "TripUnit", sv_gen);
ev_trip_first = ODEevent("trip", net, "TimeSpan", [0,1.5], "TripUnit", sv_gen);
ev_nan = ODEevent("nan", net, "TimeSpan", [1,1.2], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", NaN);
str_warn = "GUILDA:PowerNetwork:SimulationIncomplete";


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
assert(DebugScript.helper.msg_id(ME) == "GUILDA:ODEsolver:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "phase 2") && contains(ME.message, "t = [1, 1.5]"), ME.message)
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:ode15s:MassMatrixAllZero", DebugScript.helper.msg_id(ME.cause{1}))


%% Warning and message name the reason
lastwarn("");
[~, ~, output] = run(net, [0,2], ev_trip_later);
[str_msg, id] = lastwarn(); id = DebugScript.helper.msg_id(str_msg, id);
assert(id == str_warn, id)
assert(contains(str_msg, output.message))
assert(contains(output.message, "t = 1 s of 2 s") && contains(output.message, output.exception.message), output.message)


%% Failed initial condition returns the completed phases
[sol, flag, output] = run(net, [0,2], ev_nan);
assert(flag == -1)
assert(output.tEnd == 1 && sol.rv_t(end) == 1 && output.nPhasesDone == 1)
ME = output.exception;
assert(DebugScript.helper.msg_id(ME) == "GUILDA:ODEsolver:InitialConditionFailed", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "phase 2") && contains(ME.message, "t = [1, 1.2]"), ME.message)
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:daeic12:NeedBetterY0", DebugScript.helper.msg_id(ME.cause{1}))
assert(DebugScript.helper.msg_id(ME.cause{2}) == "MATLAB:decic:IndexGTOne", DebugScript.helper.msg_id(ME.cause{2}))


%% First phase failure returns an empty result
[sol, flag, output] = run(net, [0,2], ev_trip_first);
assert(flag == -1)
assert(output.tEnd == 0 && output.nPhasesDone == 0)
assert(isempty(sol.rv_t) && size(sol.rm_variable,1) == 0 && width(sol.rm_variable) == height(sol.tab_variable))
assert(isempty(sol.odeResults.t) && height(sol.odeResults.Bus(1).V) == 0)
assert(contains(output.message, "phase 1"), output.message)
expect_error(@() sol.get_point(0), "GUILDA:ODEresult:PointTime")


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
str_dir = tempname;
mkdir(str_dir);
c_dir = onCleanup(@() rmdir(str_dir, "s"));
str_csv = fullfile(str_dir, "empty.csv");
sol.Export(str_csv);
tab = readtable(str_csv);
assert(height(tab) == 0 && any(string(tab.Properties.VariableNames) == "t"))
str_mat = fullfile(str_dir, "empty.mat");
sol.Export(str_mat);
s = load(str_mat);
assert(s.flag == -1 && DebugScript.helper.msg_id(s.output.exception) == "GUILDA:ODEsolver:PhaseFailed")


%% Plot and Export options work when the first phase fails
str_dir = tempname;
mkdir(str_dir);
c_dir = onCleanup(@() rmdir(str_dir, "s"));
str_csv = fullfile(str_dir, "opt.csv");
[~, flag] = run(net, [0,2], ev_trip_first, "Plot", true, "Export", str_csv);
close all
assert(flag == -1 && isfile(str_csv))


%% Working data is restored after a failed phase
run(net, [0,2], ev_trip_later);
for i = 1:numel(net.a_Bus)
    for j = 1:numel(net.a_Bus{i}.a_Component)
        comp = net.a_Bus{i}.a_Component{j};
        assert(get_private(comp, "l_isConnect"), comp.str_tag)
    end
end
ref = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() ref.initialize);
ref.solver_ODE.Progress = "none";
sol = run(net, [0,1]);
sol_ref = run(ref, [0,1]);
assert(isequaln(sol.rm_variable, sol_ref.rm_variable))


%% Input function error is still raised
ev = ODEevent("in", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) boom(t));
ME = catch_error(@() run(net, [0,4], ev));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:ODEsolver:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "phase 2") && DebugScript.helper.msg_id(ME.cause{1}) == "DebugScript:boom")


%% Input function error with a MATLAB identifier is still raised
ev = ODEevent("in", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) bad_index(t));
ME = catch_error(@() run(net, [0,4], ev));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:ODEsolver:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:badsubscript", DebugScript.helper.msg_id(ME.cause{1}))


%% Solver error of an input function is still raised
ev = ODEevent("in", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) own_solver(t));
ME = catch_error(@() run(net, [0,4], ev));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:ODEsolver:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:ode15s:MassMatrixAllZero", DebugScript.helper.msg_id(ME.cause{1}))


%% Wrong solver settings are still raised
net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
net2.solver_ODE.Progress = "none";
ME = catch_error(@() run(net2, [0,1], "SolverOptions", matlab.ode.options.ODE45));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:ODEsolver:PhaseFailed", DebugScript.helper.msg_id(ME))
assert(DebugScript.helper.msg_id(ME.cause{1}) == "MATLAB:ode45:MassSingularYes", DebugScript.helper.msg_id(ME.cause{1}))


%% Convergence failure of the initial condition returns the completed phases
ev = ODEevent("huge", net, "TimeSpan", [1,1.2], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", 1e6);
[~, flag, output] = run(net, [0,2], ev);
assert(flag == -1 && output.tEnd == 1)
assert(DebugScript.helper.msg_id(output.exception.cause{2}) == "MATLAB:decic:ConvergenceFail", DebugScript.helper.msg_id(output.exception.cause{2}))


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

function expect_error(fcn, str_id)
    ME = catch_error(fcn);
    assert(DebugScript.helper.msg_id(ME) == str_id, DebugScript.helper.msg_id(ME))
end

function sv = generators(net)
    sv = strings(0,1);
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            comp = net.a_Bus{i}.a_Component{j};
            if startsWith(comp.str_tag, "SG")
                sv(end+1,1) = comp.str_tag; %#ok<AGROW>
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
