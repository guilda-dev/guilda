function export_csv(obj)
    
    path = uigetdir;
    time_text = datestr(datetime('now'),'yyyy_mm_dd_HH_MM_ss');
    subpath = [path,'/DataBox_',time_text];
    mkdir(subpath)


    time = obj.t;
    time = table(time);

    nbus = numel(obj.X);

    path_comp = [subpath,'/component_state'];
    mkdir(path_comp)
    for i = 1:nbus
        name = myclass(obj.net_data.component{i,'class'})
        filename = [path_comp,'/component',num2str(i),'_',name,'.csv'];
        writetable([time,obj.X{i}], filename)
    end

    path_bus = [subpath,'/bus_powerflow'];
    mkdir(path_bus)
    for i = 1:nbus
        filename = [path_bus,'/bus',num2str(i),'.csv'];
        writetable([time,add(obj.V{i},'V'),add(obj.I{i},'I'),obj.power{i}], filename)
    end


    path_cl = [subpath,'/controller_local'];
    mkdir(path_cl)
    path_clx = [path_cl,'/state'];
    path_clu = [path_cl,'/u'];
    mkdir(path_clx)
    mkdir(path_clu)
    for i = 1:size(obj.net_data.controller_local,1)
        name = myclass(obj.net_data.controller_local{i,'class'});
        filename = [path_clx,'/controller',num2str(i),'_',name,'.csv'];
        writetable(obj.Xk{i}, filename)
        filename = [path_clu,'/controller',num2str(i),'_',name,'.csv'];
        writetable(obj.U{i}, filename)
    end


    path_cg = [subpath,'/cottroller_global'];
    mkdir(path_cg)
    path_cgx = [path_cg,'/state'];
    path_cgu = [path_cg,'/u'];
    mkdir(path_cgx)
    mkdir(path_cgu)
    for i = 1:size(obj.net_data.controller_global,1)
        name = myclass(obj.net_data.controller_global{i,'class'});
        filename = [path_cgx,'/controller',num2str(i),'_',name,'.csv'];
        writetable(obj.Xk_global{i}, filename)
        filename = [path_cgu,'/controller',num2str(i),'_',name,'.csv'];
        writetable(obj.U_global{i}, filename)
    end
end


function T = add(T,word)
    var = T.Properties.VariableNames;
    var = tools.cellfun(@(v) [word,v], var);
    T.Properties.VariableNames = var;
end

function name = myclass(name)
    idx = find(name=='.',1,'last');
    if ~isempty(idx)
        name = name(idx+1:end);
    end
end