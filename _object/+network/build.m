function net = build(filepath)

    if nargin < 1
        filepath = [uigetdir(fullfile(pwd,'_object','+network'),'Choose network data'),'/'];
    else
        filepath = check_filepath(filepath);
    end
    
    net = power_network;

    idx_srash = find(filepath(1:end-1)=='/',1,"last");
    if isempty(idx_srash); idx_srash=0; end
    Tag = filepath(idx_srash+1:end-1);
    if Tag(1)=='+'; Tag = Tag(2:end); end
    net.Tag = Tag;
    
% define bus class 
    Tab_bus = readtable([filepath,'bus.csv']);
    for i = 1:size(Tab_bus, 1)
        shunt = Tab_bus{i, {'G_shunt', 'B_shunt'}};
        bus_type = Tab_bus{i, 'type'};
        if iscell(bus_type); bus_type = bus_type{1}; end
        switch bus_type
            case {'slack','bus_slack',1}
                V_abs = Tab_bus{i, 'V_abs'};
                V_angle = Tab_bus{i, 'V_angle'};
                net.add_bus(bus.slack(V_abs, V_angle, shunt));
                
            case {'PV','bus_PV',2}
                V_abs = Tab_bus{i, 'V_abs'};
                P = Tab_bus{i, 'P_gen'};
                net.add_bus(bus.PV(P, V_abs, shunt));
                
            case {'PQ','bus_PQ',3}
                P = Tab_bus{i, 'P_load'};
                Q = Tab_bus{i, 'Q_load'};
                net.add_bus(bus.PQ(-P, -Q, shunt));
        end
    end
    
% define branch class
    Tab_branch = readtable([filepath,'branch.csv']);
    for i = 1:size(Tab_branch, 1)
        if Tab_branch{i, 'tap'} == 0
            br = branch.pi(...
                    Tab_branch{i, 'bus_from'},          Tab_branch{i, 'bus_to'},...
                    Tab_branch{i, {'x_real', 'x_imag'}},Tab_branch{i, 'y'});
        else
            br = branch.pi_transformer(...
                    Tab_branch{i, 'bus_from'},          Tab_branch{i, 'bus_to'},...
                    Tab_branch{i, {'x_real', 'x_imag'}},Tab_branch{i, 'y'},...
                    Tab_branch{i, 'tap'},               Tab_branch{i, 'phase'});
        end
        net.add_branch(br);
    end

% set component class
    Tab = struct;
    for i = 1:size(Tab_bus, 1)
        Tab = set_any(net.a_bus{i},Tab_bus(i,:),Tab,filepath);
    end
    
    net.initialize();
end

function filepath = check_filepath(filepath)
    if ~isfolder(filepath)
        if isfolder([pwd,'/',filepath])
            filepath = [pwd,'/',filepath];

        elseif isfolder(['+network/',filepath])
            filepath = ['+network/',filepath];

        elseif isfolder(['+network/+',filepath])
            filepath = ['+network/+',filepath];
        else
            error("filepath couldn't be identified")
        end
    end

    if filepath(end)~='/'
        filepath = [filepath,'/'];
    end
end


function Tab_memory = set_any(targetObj,Tab,Tab_memory,filepath)
    if ismember('SetClass',fieldnames(Tab)) && ismember('SetMethod',fieldnames(Tab))
        name   = Tab{:,'SetClass'}{1};
        if ~isempty(name)
            name   = split(name,  {' ',',','/','-',newline});
            method = Tab{:,'SetMethod'}{1};
            method = split(method,{' ',',','/','-',newline});
            for i = 1:numel(name)
                [domain,data,Tab_memory] = get_obj(name{i},Tab_memory,filepath);
                if isempty(data)
                    if ~isempty(domain)
                        try 
                            Instance = eval([domain,'()']);
                            targetObj.(method{i})(Instance);
                        catch
                            warning(['Could not construct "',domain,'" to assign to class "',class(targetObj),'"'])
                        end
                    end
                else
                    idx = find(data{:,'ID'} == Tab{:,'ID'});
                    for j = idx(:)'
                        data_j = data(j,:);
                        except = {'ID','SetClass','SetMethod'};
                        include = ismember(except,data_j.Properties.VariableNames);
                        data_j(:,except(include)) = [];
                        Instance = eval([domain,'(data_j)']);
                        Tab_memory = set_any(Instance,data(j,:),Tab_memory,filepath);
                        targetObj.(method{i})(Instance);
                    end
                end
            end
        end
    end
end

function [domain,data,Tab_memory] = get_obj(name,Tab_memory,filepath)
    domain = [];
    data   = [];
    if ~isempty(name)
        domain = supporters.DNS(name);
        if ~isnan(domain)
            field = strrep(name,'.','_dot_');
            if isfield(Tab_memory,field)
                data = Tab_memory.(field);
            else
                file = [filepath,name,'.csv'];
                if ~isfile(file); return; end
                data = readtable(file);
                Tab_memory.(field) = data;
            end
        end
    end
end