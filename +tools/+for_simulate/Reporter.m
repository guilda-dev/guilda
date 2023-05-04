classdef Reporter < handle
    
    properties
        time_end
        time_start

        flag
        plotfunc
        reset
        do_report
        
        dialog
        percent

        sampling_period = 0.1;
        last_time = 0;
    end
    
    methods
        function obj = Reporter(time_start, time_end, do_report, plotfunc)
            obj.time_end = time_end;
            obj.time_start = time_start;
            obj.flag = false;
            obj.reset = false;
            obj.do_report = do_report;
            obj.last_time = time_start;
            obj.sampling_period = (time_end-time_start)/50;
            if nargin < 3
                obj.plotfunc = {@odephas2};
            else
                if ~iscell(plotfunc) && ~isempty(plotfunc)
                    plotfunc = {plotfunc};
                end
                obj.plotfunc = plotfunc;
            end
        end
        
        function f = report(obj, t, x, flag, reset_time, t_start)
            if isempty(obj.plotfunc)
                f = false;
            else
                f = tools.vcellfun(@(fcn) fcn(t,x,flag), obj.plotfunc);
                f = any(f);
            end
            t_now = datetime;
            [~, ~, ds] = hms(t_now - t_start);
            if ds > reset_time
                f = true;
            end
            if f
                obj.reset = true;
            end
            if ~obj.do_report
                return;
            end
            if strcmp(flag, 'done') 
                if obj.percent == 1
                    delete(obj.dialog)
                end
                return
            elseif ~obj.flag && strcmp(flag, 'init')
                obj.dialog = waitbar(0,'','Name','Simulation in progress...');
                obj.flag = true;

            else
                if ~isgraphics(obj.dialog)
                    f = true;
                    obj.reset = true;
                    delete(obj.dialog)
                    return
                end
                if numel(t)==1
                    if (t-obj.last_time) >= obj.sampling_period || t == obj.time_end
                        obj.last_time = t;
                        obj.percent = (t-obj.time_start)/(obj.time_end-obj.time_start);
                        waitbar(obj.percent,obj.dialog,sprintf('Time: %0.2f(s) / %0.2f(s)',t,obj.time_end))
                    end
                end
            end
            
        end
        
    end
    
end

