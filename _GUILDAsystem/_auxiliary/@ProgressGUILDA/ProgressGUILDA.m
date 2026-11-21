classdef ProgressGUILDA < auxiliary
% Progress display of an analysis: a dialog, one line per step in the Command Window, or nothing.
%
% The analyses create one per run from their Progress option: net.calculate_powerflow,
% net.calculate_fixed_input_powerflow, net.calculate_continuation_powerflow,
% net.calculate_optimal_powerflow and net.simulate. The mode is
%
% - "dialog": a dialog that opens only when the run lasts 0.5 s or longer, so a short run
%   shows nothing. It shows the last text given to update; while the run gives no new text,
%   the bar keeps moving (a timer redraws it every 0.25 s). Inside the GUILDA app
%   (GUILDA.launch_gui) it is a uiprogressdlg of the app window, otherwise a waitbar. It
%   closes when the object is deleted (the analyses delete it with onCleanup, also on an
%   error). Under matlab -batch "dialog" shows nothing.
% - "disp": update prints each new text as one line in the Command Window (the time
%   simulation prints its text bar instead).
% - "none": nothing.
%
% true and false are taken as "dialog" and "none". For the time simulation, SolverODE.solve
% passes OutputFcn and Events to the MATLAB ode object; they show the time reached and stop
% the integration when the run takes longer than timelimit.
%
% See also SolverODE, SolverPF, SolverCPF, SolverOPF
    properties % Display
        message (1,1) string = "|"      % Text printed at the end of the phase of a time simulation (the outcome of the phase).
        timeoffset (1,1) double = 0     % [s] Start time of the current phase (ode times start at 0).
    end

    properties(SetAccess=protected) % Callbacks
        OutputFcn = @(t,x,flag) false;  % Output function given to the ode solver options (OutputFcn). <@Type> function_handle
    end

    properties(SetAccess=protected) % State (read by the analyses and the tests)
        mode                            % Display mode: "none", "disp" or "dialog".
        s_title (1,1) string = ""       % Title of the dialog (name of the analysis).
        s_text (1,1) string = ""        % Last text given to update.
        r_fraction (1,1) double = NaN   % Last fraction given to update (NaN: unknown, the bar moves).
        timelimit                       % [s] Limit of the wall-clock time of the whole run.
        tlim                            % [s] Simulation time [t0, tend].
        tspan                           % [s] Length of the simulation time.
        tlast                           % [s] Time of the last update of the display.
        phase = 0;                      % Number of the current phase.
        last_warn                       % Last warning when the display was drawn.
        start_time                      % Value of tic at the start of the run (time keeper, and the 0.5 s of the dialog).
        ToBeContinue = true;            % False when the run exceeded timelimit.
        dialog = [];                    % Dialog (mode "dialog"): a waitbar figure or a uiprogressdlg; [] before it opens.
        t_draw = [];                    % Value of tic at the last drawing of the dialog.
        n_draw = 0;                     % Number of drawings of the dialog (position of a moving bar).
        h_timer = [];                   % Timer that opens the dialog after 0.5 s and redraws it (mode "dialog").
    end

    methods
        function obj = ProgressGUILDA(mode, s_title, t_simulate, timelimit)
        % Create the progress display of an analysis.
            arguments (Input)
                mode                      = "disp"  % Display mode: "dialog", "disp", "none" (text), true ("dialog") or false ("none").
                s_title    (1,1) string   = ""      % Title of the dialog (name of the analysis).
                t_simulate (1,:) double   = [0,100] % [s] Simulation time [t0, tend] (time simulation only).
                timelimit  (1,1) double {mustBePositive} = inf;  % [s] Limit of the wall-clock time of the whole run (time simulation only).
            end
            arguments (Output)
                obj  % The progress display.
            end
            if islogical(mode) || isnumeric(mode)
                sv_mode = ["none", "dialog"];
                mode = sv_mode(1 + logical(mode));
            end
            mustBeTextScalar(mode);
            mode = string(mode);
            mustBeMember(mode, ["none","disp","dialog"]);
            if mode == "dialog" && (batchStartupOptionUsed || ~feature("ShowFigureWindows"))
                mode = "none";      % no window to show it in
            end
            obj.mode      = mode;
            obj.s_title   = s_title;
            obj.timelimit = timelimit;
            obj.tlim      = t_simulate;
            obj.tspan     = t_simulate(end)-t_simulate(1);
            obj.start_time = tic;
            if mode == "dialog"
                obj.h_timer = timer("StartDelay", 0.5, "Period", 0.25, "ExecutionMode", "fixedSpacing", ...
                    "ObjectVisibility", "off", "Tag", "GUILDA:ProgressGUILDA", "TimerFcn", @(~,~) obj.update(obj.s_text, obj.r_fraction), ...
                    "ErrorFcn", @(~,~) []);
                start(obj.h_timer);
            end
        end

        function set.mode(obj,val)
            switch val
                case 'none'
                    obj.OutputFcn = @obj.time_keeper;   %#ok
                case 'disp'
                    obj.OutputFcn = @obj.dispFcn;       %#ok
                case 'dialog'
                    obj.OutputFcn = @obj.dialogFcn;     %#ok
            end
            obj.mode = val;
        end

        function delete(obj)
        % Stop the timer and close the dialog.
            % No arguments block: a delete with one is not the destructor (isvalid stays true).
            if ~isempty(obj.h_timer) && isvalid(obj.h_timer)
                stop(obj.h_timer);
                delete(obj.h_timer);
            end
            if ~isempty(obj.dialog) && isvalid(obj.dialog)
                delete(obj.dialog);
            end
        end

        stop = update(obj, s_text, r_fraction)
        f = dialogFcn(obj,t,x,flag)
        f = dispFcn(obj,t,x,flag)
        [f,t,flag] = time_keeper(obj,t,~,flag)
        [value,isterminal,direction] = Events(obj,t)
    end

    methods(Access=private)
        disp_header(obj, t)
        disp_init(obj,t)
    end
end
