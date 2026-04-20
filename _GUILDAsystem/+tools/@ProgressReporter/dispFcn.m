function f = dispFcn(obj,percent,flag)
    arguments
        obj 
        percent = 0;
        flag    = [];
    end
    if ~isempty(flag)
        return
    end
    f= false;
    switch obj.flag
        case "init"
            disp(obj.msg)
            indent = repmat(' ',1,numel(obj.indentTag));
            if obj.dispGuideBar
                disp([  indent,'|   10%  20%  30%  40%  50%  60%  70%  80%  90%   |',newline,...
                        indent,'|----o----o----o----o----o----o----o----o----o----|'])
            end
            fprintf([obj.indentTag,'|'])
            obj.last_meter = 0;
            obj.last_warn  = lastwarn;
            obj.flag = "progress";
        case "progress"
            wid = lastwarn;
            if ~strcmp(obj.last_warn,wid)
                obj.flag = "init";
                obj.dispFcn(percent);
            end
            per = floor(percent*50);
            if per>=50
                obj.flag = "done";
                fprintf(repmat('>',1,49-obj.last_meter));
                obj.dispFcn;
                return
            end
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
            f = true;
            return
        case "done"
            disp('|')
            return
    end
    obj.msg = '';
end