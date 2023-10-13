classdef Factory_Reporter < handle
    
    properties
        time_end
        time_start

        flag
        plotfunc
        reset
        do_report
        
        dialog
        percent

        sampling_period;
        last_time;
    end
    
    methods
        function obj = Factory_Reporter(time, net, options)
            obj.time_start = time(1);
            obj.time_end = time(end);
            obj.flag = false;
            obj.reset = false;
            obj.do_report = options.do_report;

            % Outputfunctionについて整理する
                OutputFcn = organize_OutputFcn(net,options.OutputFcn);
                plotfunc = [];
                if ~isempty(OutputFcn.Gridcode)
                    plotfunc = [plotfunc,{@checker.live}];
                    options.do_report = false;
                end
                if ~isempty(OutputFcn.Response)
                    res = supporters.for_simulate.reporter.Response_reporter(time,obj,holder,OutputFcn.Response);
                    plotfunc = [plotfunc,{@res.plotFcn}];
                    options.do_report = false;
                end
                if ~isempty(OutputFcn.other)
                    plotfunc = [plotfunc,OutputFcn.other];
                end
                obj.plotfunc = plotfunc;

            obj.last_time = time(1);
            obj.sampling_period = ( time(end) - time(1) )/100;
            
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

function OutputFcn = organize_OutputFcn(net,Fcn,unistate)
    if nargin < 3
        unistate = unique(tools.hcellfun(@(b) b.component.get_state_name, net.a_bus));
    end

    OutputFcn = struct('Gridcode',[],'Response',[],'other',[]);

    if iscell(Fcn)
        for i = 1:numel(Fcn)
            temp = organize_OutputFcn(net,Fcn{i},unistate);
            OutputFcn.Response = unique([OutputFcn.Response, temp.Response]);
            OutputFcn.Gridcode = unique([OutputFcn.Gridcode, temp.Gridcode]);
            OutputFcn.other    = unique([OutputFcn.other   , temp.other   ]);
        end 
        return
    end

    if ischar(Fcn)
        if ismember(Fcn,unistate)
            OutputFcn.Response = {Fcn};
        elseif ismember(Fcn,{'GridCode','grid_code','gridcode'})
            n(1) = numel(net.a_bus);
            n(2) = numel(net.a_branch);
            n(3) = numel(net.a_controller_local)+numel(net.a_controller_global);
            list = {'component','branch','controller'};
            OutputFcn.Gridcode = list(n>0);
        end
    elseif isa(Fcn,'function_handle')
        OutputFcn.other = {Fcn};
    end
end

