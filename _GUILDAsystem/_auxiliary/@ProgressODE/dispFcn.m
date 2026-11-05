function f = dispFcn(obj,t,x,flag)
% Update the text bar (output function of mode "disp").
    arguments (Input)
        obj
        t     % [s] Time of the solver (empty or [t0 tend] at "init", empty at "done").
        x     % States of the solver.
        flag  % "init", "done", "break" or empty.
    end
    arguments (Output)
        f     % True to stop the integration (always false).
    end
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
