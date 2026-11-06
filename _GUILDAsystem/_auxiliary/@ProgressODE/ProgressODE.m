classdef ProgressODE < auxiliary
% Progress display and time keeper of a time simulation.
%
% SolverODE.solve creates one per run and passes OutputFcn and Events to the MATLAB ode
% object. It shows the progress as a waitbar ("dialog") or a text bar ("disp"), or nothing
% ("none"), and stops the integration when the run takes longer than timelimit.
%
% See also SolverODE
    properties % Display
        message (1,1) string = "|"      % Text printed at the end of the phase (the outcome of the phase).
        timeoffset (1,1) double = 0     % [s] Start time of the current phase (ode times start at 0).
    end
    
    properties(SetAccess=protected) % Callbacks
        OutputFcn = @(t,x,flag) false;  % Output function given to the solver options (OutputFcn). <@Type> function_handle
    end

    properties%(Access=protected) % State
        mode                            % Display mode: "none", "disp" or "dialog".
        timelimit                       % [s] Limit of the wall-clock time of the whole run.
        tlim                            % [s] Simulation time [t0, tend].
        tspan                           % [s] Length of the simulation time.
        tlast                           % [s] Time of the last update of the display.
        phase = 0;                      % Number of the current phase.
        last_warn                       % Last warning when the display was drawn.
        start_time                      % Value of tic at the start of the run (time keeper).
        ToBeContinue = true;            % False when the run exceeded timelimit.
        dialog = nan;                   % Waitbar figure (mode "dialog").
    end

    methods
        function obj = ProgressODE(mode, t_simulate, timelimit)
        % Create the progress display of a simulation.
            arguments (Input)
                mode       (1,1) string {mustBeMember(mode,["none","disp","dialog"])}  = 'disp'; % Display mode.
                t_simulate (1,:) double = [0,100] % [s] Simulation time [t0, tend].
                timelimit  (1,1) double {mustBePositive}  = inf; % [s] Limit of the wall-clock time of the whole run.
            end
            arguments (Output)
                obj % The progress display.
            end
            obj.mode      = mode;
            obj.timelimit = timelimit;
            obj.tlim      = t_simulate;
            obj.tspan     = t_simulate(end)-t_simulate(1);
            obj.start_time = tic;
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

        f = dialogFcn(obj,t,x,flag)
        function delete(obj)
        % Close the waitbar.
            arguments (Input)
                obj
            end
            if isgraphics(obj.dialog)
                delete(obj.dialog);
            end
        end

        f = dispFcn(obj,t,x,flag)
        [f,t,flag] = time_keeper(obj,t,~,flag)
        [value,isterminal,direction] = Events(obj,~,~)
    end

    methods(Access=private)
        disp_header(obj, t)
        disp_init(obj,t)
    end
end
