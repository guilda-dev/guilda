function f = dispFcn(obj,percent)
    f= true;
    switch obj.flag
        case "init"
            disp(obj.msg)
            disp([  '|        10%       20%       30%       40%       50%       60%       70%       80%       90%        |',newline,...
                    '|---------o---------o---------o---------o---------o---------o---------o---------o---------o---------|'])
            fprintf('|')
            obj.last_meter = 0;
            obj.flag = "progress";
        case "progress"
            wid = lastwarn;
            if ~strcmp(obj.last_warn,wid)
                obj.flag = "init";
                obj.dispFcn(percent)
                obj.last_warn = wid;
            end
            per = floor(percent*100);
            steps = per - obj.last_meter;
            if steps > 0
                fprintf(repmat('>',1,steps))
                obj.last_meter = per;
            end
            return
        case "nextphase"
            obj.flag = "progress";
            obj.dispFcn(percent)
            disp([sprintf('\b'),'|',obj.msg])
            fprintf(['|',repmat(' ',1,obj.last_meter-1),'|'])
        case "stop"
            disp(['|',obj.msg])
            f = false;
            return
        case "done"
            disp('|')
            return
    end
    obj.msg = '';
end