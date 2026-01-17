function f = dialogFcn(obj,percent)
    f = true;
    switch obj.flag
        case "init"
            disp(obj.msg)
            obj.dialog = waitbar(0,' ','Name','Simulation in progress...');
            obj.last_meter = 0;
            obj.flag = "progress";
        case "progress"
            if ~isgraphics(obj.dialog)
                obj.flag = "init";
                obj.dialogFcn(percent);
            end
            per = floor(percent*100);
            if per-obj.last_meter >= 0.1
                waitbar(percent,obj.dialog,[num2str(per),'%',newline,obj.msg])
                obj.last_meter = per;
            end
        case "nextphase"
            disp(['<<Report history>> ',obj.msg]);
            obj.flag = "progress";
            obj.dialogFcn(percent);
        case "stop"
            disp(['<<Report history>> ',obj.msg]);
            delete(obj.dialog)
            f = false;
        case "done"
            delete(obj.dialog)
    end
end