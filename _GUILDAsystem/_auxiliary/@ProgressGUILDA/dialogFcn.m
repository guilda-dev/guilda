function f = dialogFcn(obj,t,x,flag)
% Update the dialog with the time reached (output function of mode "dialog").
    arguments (Input)
        obj
        t     % [s] Time of the solver (empty or [t0 tend] at "init", empty at "done").
        x     % States of the solver.
        flag  % "init", "done", "break" or empty.
    end
    arguments (Output)
        f  % True to stop the integration (always false).
    end
    [f,t,flag] = obj.time_keeper(t,x,flag);

    switch char(flag)
        case 'init'
            obj.phase = obj.phase +1;
            obj.tlast = t(1);
            return
        otherwise
            if isempty(t)
                return
            end
            per = (t(end)-obj.tlast)/obj.tspan;
            if per>= 0.01
                obj.update(sprintf(['Time: %0.2f(s) / %0.2f(s)',newline,'phase : %.1d'], t(end), obj.tlim(end), obj.phase), ...
                           (t(end)-obj.tlim(1))/obj.tspan);
                obj.tlast = floor(per*100)/100 * obj.tspan + obj.tlast;
            end
    end
end
