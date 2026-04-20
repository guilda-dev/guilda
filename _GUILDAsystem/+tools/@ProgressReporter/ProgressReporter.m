classdef ProgressReporter < auxiliary
    properties
        tlim         (1,1) duration
        notify       (1,1) logical
        dispGuideBar (1,1) logical
        indentTag    (1,:) char
    end
    
    properties(SetAccess=protected)
        mode   (1,1) string {mustBeMember(mode,["disp","dialog","none"])} = "disp";
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
                opt.Mode      (1,1) string {mustBeMember(opt.Mode,["disp","dialog","none"])} = "disp";
                opt.TimeLimit (1,1) double  = inf;
                opt.Notify    (1,1) logical = false;
                opt.GuideBar  (1,1) logical = true;
                opt.indentTag (1,:) char    = '';
            end
            obj.mode         = opt.Mode;
            obj.tlim         = duration(0,0,opt.TimeLimit);
            obj.notify       = opt.Notify;
            obj.dispGuideBar = opt.GuideBar;
            obj.indentTag    = opt.indentTag;
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
            if val<=0
                error(GUILDAconfig.lang("制限時間(s)は0より大きい値である必要があります。","Time limit (s) must be positive."))
            end
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