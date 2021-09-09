classdef Reporter < handle
    
    properties
        progress
        time_end
        time_start
        frequency = 0.1;
        w = 50;
        l = 0;
        n = 0;
        flag;
        plotfunc
        reset
        do_report
    end
    
    methods
        function obj = Reporter(time_start, time_end, do_report, plotfunc)
            obj.progress = 0;
            obj.time_end = time_end;
            obj.time_start = time_start;
            obj.l = 0;
            obj.n = 0;
            obj.flag = false;
            obj.reset = false;
            obj.do_report = do_report;
            if nargin < 3
                obj.plotfunc = @odephas2;
            else
                obj.plotfunc = plotfunc;
            end
        end
        
        function f = report(obj, t, x, flag, reset_time, t_start)
            if isempty(obj.plotfunc)
                f = false;
            else
                f = obj.plotfunc(t, x, flag);
            end
            t_now = datetime;
            [~, ~, ds] = hms(t_now - t_start);
            if ds > reset_time
                f = true;
            end
            if f
                obj.reset = true;
                if obj.do_report
                    fprintf('\n');
                end
            end
            if ~obj.do_report
                return;
            end
            %             f = false;
            if strcmp(flag, 'done')
                if obj.n==obj.w
                    fprintf('|\n');
                end
                return
            elseif ~obj.flag && strcmp(flag, 'init')
                l = length(repmat('=>', obj.w));
                fprintf([num2str(obj.time_start), '|', repmat(' ', 1, l), '|', num2str(obj.time_end)]);
                fprintf('\n');
                fprintf(repmat(' ', 1, length(num2str(obj.time_start))));
                fprintf('|');
                obj.flag = true;
            else
                r = (t-obj.time_start)/(obj.time_end-obj.time_start);
                n_lack = floor(r*obj.w) - obj.n;
                if n_lack > 0
                    for i = 1:n_lack
                        fprintf('=>');
                        obj.n = obj.n + 1;
                    end
                end
            end
            
        end
        
    end
    
end

