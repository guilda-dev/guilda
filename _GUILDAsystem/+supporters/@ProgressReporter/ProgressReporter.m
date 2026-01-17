classdef ProgressReporter < handle
    properties
        tlim   (1,1) duration
        notify (1,1) logical
    end
    
    properties(SetAccess=protected)
        mode   (1,1) string {mustBeMember(mode,["disp","dialog","none"])}
        msg    (1,:) char = '';
        flag   (1,1) string {mustBeMember(flag,["init","progress","nextphase","stop","done"])} = "init";

        % Fcn
        EventFcn
        TimerFcn = @() false;

        % For Time keeper
        start_time

        % For mode = "disp"
        last_meter
        last_warn  = '';

        % For mode = "dialog"
        dialog
        
    end
    
    methods
        f = dispFcn(obj,percent)
    end

    methods

        function obj = ProgressReporter(opt)
            arguments
                opt.Mode      (1,1) string {mustBeMember(opt.Mode,["disp","dialog","none"])}
                opt.TimeLimit (1,1) double  = inf;
                opt.Notify    (1,1) logical = false;
            end
            obj.mode   = opt.Mode;
            obj.tlim   = duration(0,0,opt.TimeLimit);
            obj.notify = opt.Notify;
        end

        function set.mode(obj,val)
            obj.mode = val;
            switch val
                case "none"   ; obj.EventFcn = @(p) obj.flag~="stop";   %#ok
                case "disp"   ; obj.EventFcn = @obj.dispFcn;   %#ok
                case "dialog" ; obj.EventFcn = @obj.dialogFcn; %#ok
            end
        end

        function set.tlim(obj,val)
            assert(val>0, config.lang("制限時間(s)は0より大きい値である必要があります。","Time limit (s) must be positive."))
            if ~isinf(val)
                obj.TimerFcn = @obj.time_keeper;  %#ok
            end
        end

        function stop(obj,msg,opt)
            arguments
                obj 
                msg (1,:) char
                opt.flag (1,1) string {mustBeMember(opt.flag,["nextphase","stop"])} = "nextphase";
            end
            obj.msg  = msg;
            obj.flag = opt.flag;
        end

        function time_keeper(obj)
            switch obj.flag
                case "init"
                    obj.start_time = datetime;
                case "progress"
                    if (datetime - obj.start_time) > obj.tlim
                        obj.msg  = ' <Timeout>';
                        obj.flag = "stop";
                    end
            end
        end

        function [value,isterminal,direction] = Events(obj,percent)
            if percent>=1
                obj.flag = "done";
                if obj.notify
                    data = load('train.mat');
                    sound( data.y, data.Fs);
                end
            end
            obj.TimerFcn();
            value = obj.EventFcn(percent);
            isterminal = 1;
            direction  = 0;
        end
    end
end