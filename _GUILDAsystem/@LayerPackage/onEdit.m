function onEdit(obj, log, time, tab)
    arguments
        obj 
        log  (1,1) string = "";                                                     %#ok
        time (1,1) string = string(datetime('now','Format','dd/MM/uuuu HH:mm:ss')); %#ok
        tab  (1,3) table  = table(time, obj.getTag(true,"/"), log)
    end
    tab.Properties.VariableNames = {'timestamp','ID','log'};
    obj.editFlag = "editted";
    obj.editLog  = [obj.editLog; tab];
    if ~isnan(obj.parent)
        obj.parent.onEdit([],[],tab)
    end
end