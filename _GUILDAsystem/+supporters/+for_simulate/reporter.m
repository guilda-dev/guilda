classdef reporter < handle
    properties
        SimulationTime (1,2) double = [0,10];
        StartTime      (1,1) datetime
        TimeLimit      (1,1) double {mustBePositive} = inf
        OutputFcn      (1,1) function_handle
    end
    methods
        function initialize(obj,timelimit,dialog)
            arguments
                obj 
                timelimit  
                dialog     (1,1) string {mustBeMember(dialog, ["disp","dialog","none"])} = "dialog"; 
            end
            obj.TimeLimit = timelimit;
            obj.StartTime = datetime("now");
            
            switch dialog
                case "disp";   obj.OutputFcn = @obj.OutputFcn_disp;
                case "dialog"; obj.OutputFcn = @obj.OutputFcn_dialog;
                case "none";   obj.OutputFcn = @obj.TimeWatch;
            end
        end

        function flag = TimeWatch(obj,varargin)
            dt = seconds(datetime("now")-obj.StartTime);
            flag = dt<=obj.TimeLimit;
        end

        function flag = OutputFcn_disp(obj,t,x)
            flag = obj.TimeWatch;
        end
        function flag = OutputFcn_dialog(obj,t,x)
            flag = obj.TimeWatch;
        end

    end

end