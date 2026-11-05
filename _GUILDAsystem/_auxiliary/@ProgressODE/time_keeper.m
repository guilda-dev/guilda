function [f,t,flag] = time_keeper(obj,t,~,flag)
% Stop the integration when the run exceeds timelimit (output function of mode "none").
%
% Shifts t by timeoffset and records the reason of a stop in message.
    arguments (Input)
        obj
        t     % [s] Time of the solver (empty or [t0 tend] at "init", empty at "done").
        ~
        flag  % "init", "done", "break" or empty.
    end
    arguments (Output)
        f     % True to stop the integration (always false).
        t     % [s] Time shifted by timeoffset.
        flag  % Flag, set to 'done' when the run stops.
    end
    t = obj.timeoffset + t;
    f = 0;
    switch char(flag)
        case 'init'
            obj.ToBeContinue = true;
        case 'done'
            return
        case 'break'
            if isempty(obj.tlast)
                obj.message = "|(break)";
            else
                obj.message = "|(break: t="+obj.tlast+")";
            end
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
