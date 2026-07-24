classdef odeProgress < auxiliary
    properties
        message    (1,1) string = "|"
        timeoffset (1,1) double = 0
    end
    
    properties(SetAccess=protected)
        OutputFcn = @(t,x,flag) false;
    end

    properties%(Access=protected)
        mode
        timelimit

        tlim
        tspan
        tlast

        phase = 0;

        last_warn

        % For Time keeper
        start_time
        ToBeContinue = true;

        % For mode = "dialog"
        dialog = nan;
    end

    methods

        function obj = odeProgress(mode, t_simulate, timelimit)
            arguments
                mode       (1,1) string {mustBeMember(mode,["none","disp","dialog"])}  = 'disp';
                t_simulate (1,:) double = [0,100]
                timelimit  (1,1) double {mustBePositive}  = inf;
            end
            obj.mode      = mode;
            obj.timelimit = timelimit;
            obj.tlim      = t_simulate;
            obj.tspan     = t_simulate(end)-t_simulate(1);
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


        function f = dialogFcn(obj,t,x,flag)
            [f,t,flag] = obj.time_keeper(t,x,flag);

            switch char(flag)
                case 'init'
                    obj.phase = obj.phase +1;
                    obj.tlast = t(1);
                    return
                otherwise
                    if ~isgraphics(obj.dialog)
                        obj.dialog = waitbar(0,' ','Name','Simulation in progress...');
                    end
                    per = (t-obj.tlast)/obj.tspan;
                    if per>= 0.01
                        waitbar(t/obj.tspan,obj.dialog,sprintf(['Time: %0.2f(s) / %0.2f(s)',newline,'phase : %.1d'],t,obj.tlim(end), obj.phase))
                        obj.tlast = floor(per*100)/100 * obj.tspan + obj.tlast;
                    end
            end
        end
        function delete(obj)
            if isgraphics(obj.dialog)
                delete(obj.dialog);
            end
        end

        function f = dispFcn(obj,t,x,flag)
            [f,t,flag] = obj.time_keeper(t,x,flag);

            switch char(flag)
                case 'init'
                    obj.phase = obj.phase +1;
                    if obj.phase==1
                        obj.disp_header(t)
                    end
                    obj.disp_init(t)
                case 'done'
                    fprintf('\b')
                    disp(obj.message)
                    obj.message = " ";
                otherwise
                    wid = lastwarn;
                    if ~strcmp(obj.last_warn,wid)
                        obj.disp_header(obj.tlim);
                        obj.disp_init(obj.tlim);
                    end
                    per = (t-obj.tlast)/obj.tspan;
                    if per>= 0.01
                        roundper = floor(per*100);
                        fprintf(repmat('>',1,roundper))
                        obj.tlast = roundper/100 * obj.tspan + obj.tlast;
                    end
            end
        end

        function [f,t,flag] = time_keeper(obj,t,~,flag)
            t = obj.timeoffset + t;
            f = 0;
            if isinf(obj.timelimit)
                return; 
            end
            switch char(flag)
                case 'init'
                    obj.ToBeContinue = true;
                    obj.start_time = tic;
                case 'done'
                    return
                case 'break'
                    obj.message = "|(break: t="+obj.tlast+")";
                    flag = 'done';
                    return
                otherwise
                    if  obj.ToBeContinue && toc(obj.start_time) >= obj.timelimit
                        obj.ToBeContinue = false;
                        obj.message = "|(timeout: t="+t(1)+")";
                        flag = 'done';
                    end
            end
        end


        function [value,isterminal,direction] = Events(obj,~,~)
            value = obj.ToBeContinue;
            isterminal = 1;
            direction  = 0;
        end

    end

    methods(Access=private)
        function disp_header(obj, t)
            disp(' ')
            t0 = [num2str( obj.tlim(1)  ),'s'];
            te = [num2str( obj.tlim(end)),'s'];
            disp(['         ',t0,repmat(' ',[1,101-numel([t0,te])]),te])
            disp(['         |        10%       20%       30%       40%       50%       60%       70%       80%       90%        |',newline,...
                  '         |---------o---------o---------o---------o---------o---------o---------o---------o---------o---------|'])

            obj.tlast     = t(1);
            obj.last_warn = lastwarn;
        end

        function disp_init(obj,t)
            fprintf([' phase', num2str(obj.phase,"%.2d"),' |'])
            per = (t(1)-obj.tlim(1))/obj.tspan;
            if per>= 0.01
                roundper = floor(per*100);
                fprintf([repmat(' ',1,roundper-1),'|'])
                obj.tlast = roundper/100 * obj.tspan + obj.tlim(1);
            end
        end
    end
end

