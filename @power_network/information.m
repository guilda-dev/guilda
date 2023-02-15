function out = information(obj,varargin)
    %引数に与えられたネットワークのモデルのパラメータを調べる用の関数

    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'do_report', true);

    addParameter(p, 'bus'           , true);
    addParameter(p, 'branch'        , true);
    addParameter(p, 'component_para', true);
    addParameter(p, 'x_equilibrium' , true);

    addParameter(p, 'plot_graph'     , true);
    addParameter(p, 'graphVisible'   , 'wheather_plot_or_not');
    addParameter(p, 'export_tex_data', false);
    
    %addParameter(p, 'pdf', false);
    if nargin == 2
        if isstruct(varargin{1})
            para = p.Parameters;
            varargin = cell(1,numel(para)*2);
            for i = 1:numel(para)
                varargin{2*i-1} = para{i};
                value = input([para{i},'? (y/n) : '],"s");
                switch value
                    case 'y'
                        varargin{2*i}= true;
                    case 'n'
                        varargin{2*i}= false;
                end
            end
        end
    end
    parse(p, varargin{:});

    options = p.Results;
    if strcmp(options.graphVisible,'wheather_plot_or_not')
        options.graphVisible = options.plot_graph;
    end

    if options.export_tex_data
        options.bus            = true;
        options.branch         = true;
        options.component_para = true;
        options.x_equilibrium  = true;
        options.plot_graph     = true;
    end

    
    %潮流状態の情報を取得
    if options.bus
        bus = class2struct(obj.a_bus);
        out.bus = struct2table(bus);
        out.bus{:,'Vabs'}   =   abs(out.bus{:,'V_equilibrium'});
        out.bus{:,'Vangle'} = angle(out.bus{:,'V_equilibrium'});
        out.bus{:,'P'}      =  real(out.bus{:,'V_equilibrium'}.*conj(out.bus{:,'I_equilibrium'}));
        out.bus{:,'Q'}      =  imag(out.bus{:,'V_equilibrium'}.*conj(out.bus{:,'I_equilibrium'}));
    end

    %ブランチの情報を取得
    if options.branch
        branch = class2struct(obj.a_branch);
        out.branch = struct2table(branch);
    end
    
    %コンポーネント名リスト取得
    component_names = tools.vcellfun(@(b) {class(b.component)},obj.a_bus);
    [component_names,~,idx] = unique(component_names,'stable');

    for comp_idx = 1:numel(component_names)
        
        component_name = component_names{comp_idx};
        idx_dot = find(component_names{comp_idx}=='.',1,'last');
        if ~isempty(idx_dot)
            component_name = component_name(idx_dot+1:end);
        end

        % パラメータの取得
        if options.component_para
            para = [];
            if ismember('parameter',properties(component_names{comp_idx}))
                for bus_idx = (find(idx==comp_idx))'
                    comp_i = obj.a_bus{bus_idx}.component;
                    parameter = comp_i.parameter;
                    switch class(parameter)
                        case 'table'
                            temp = table2struct(parameter);
                        case 'struct'
                            temp = parameter;
                        otherwise
                            temp.memo = 'Parameter variable type is not supported.(struct,table)';
                    end
                    fname = fieldnames(temp);
                    temp.bus_idx = bus_idx;
                    temp = orderfields(temp,[{'bus_idx'};fname]);
                    para = [para,temp];
                end
                para = struct2table(para);
            end
            out.component_para.(component_name) = para;
        end
       
        %平衡点の情報を取得
        if options.x_equilibrium
            ss = [];
            stateNames = tools.arrayfun(@(ii) obj.a_bus{ii}.component.get_state_name,find(idx==comp_idx));
            stateNames = unique(horzcat(stateNames{:}),'stable');
            if numel(stateNames)~=0
                for bus_idx = (find(idx==comp_idx))'
                    comp_i = obj.a_bus{bus_idx}.component;
                    [~,isthere] = ismember(stateNames,comp_i.get_state_name);
                    unknown_itr = 1;
                    for i = 1:numel(stateNames)
                        if isthere(i)==0
                            temp = nan;
                        else
                            temp = comp_i.x_equilibrium(isthere(i));
                        end
                        try
                            ss(bus_idx).(stateNames{i}) = temp;
                        catch
                            ss(bus_idx).(['Unknown',num2str(unknown_itr)]) = temp;
                            unknown_itr = unknown_itr +1;
                        end
                    end
                end
                ss = struct2table(ss);
            end
            out.x_equilibrium.(component_name) = ss;
        end
    end
    

    if options.do_report
        if options.branch
            bar = '================';
            fprintf(['ブランチのパラメータ\n',bar,'\n'])
            disp(out.branch)
            fprintf('\n\n')
        end
        if options.bus
            fprintf(['潮流状態\n',bar,'\n'])
            disp(out.bus)
            fprintf('\n\n')
        end
        if options.component_para
            fprintf(['機器のパラメータ\n',bar,'\n'])
            fn = fieldnames(out.component_para);
            for i = 1:numel(fn)
                if ~isempty(out.component_para.(fn{i}))
                    disp(fn{i})
                    disp(out.component_para.(fn{i}))
                    fprintf('\n\n')
                end
            end
        end
        if options.x_equilibrium
            fprintf(['状態の平衡点\n',bar,'\n'])
            fn = fieldnames(out.x_equilibrium);
            for i = 1:numel(fn)
                if ~isempty(out.x_equilibrium.(fn{i}))
                    disp(fn{i})
                    disp(out.x_equilibrium.(fn{i}))
                    fprintf('\n\n')
                end
            end
        end
    end


    if options.plot_graph
        out.graph = tools.graph.plot(obj);
        out.graph.GCF = gcf;    
    end

    if options.export_tex_data
        tools.make_tex_data.main(obj,out);
    end

end


function data = class2struct(prop)

    field_i = tools.cellfun(@(prop_i) fieldnames(prop_i),prop);
    [field,~,idx] = unique(vertcat(field_i{:}),'stable');
    isthere = tools.cellfun(@(idx) ismember(field,idx),field_i);
    isthere = horzcat(isthere{:});
    
    for prop_i = 1:numel(prop)
        data(prop_i).idx = prop_i;
        for idx_field = 1:numel(field)
            fname = field{idx_field};
            if isthere(idx_field,prop_i)
                data(prop_i).(fname) = prop{prop_i}.(fname);
            else
                data(prop_i).(fname) =nan;
            end
        end
    end

    number = tools.cellfun(@(i) (1:numel(i))',field_i);
    number = vertcat(number{:});
    [~,idx] = sort(arrayfun(@(a) sum(number(idx==a)),(1:numel(field))'));
    field = [{'idx'};field(idx)];
    data = orderfields(data,field);

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%networkの情報からグラフを作成する関数%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = make_graph(net,main_Node)
    nbus = numel(net.a_bus);
    Y = net.get_admittance_matrix;
    data = struct();
    data.G = graph([Y~=0,eye(size(Y,1));eye(size(Y,1)),eye(size(Y,1))],'omitselfloops');
    
    data.Branch_idx = data.G.Edges{:,'EndNodes'};
    Edge_idx        = any(data.Branch_idx>nbus,2);
    data.graph = plot(data.G);
    layout(data.graph,'force','WeightEffect','direct')

    data.graph.LineWidth            = ones(1,size(data.Branch_idx,1));
    data.graph.LineStyle            = tools.arrayfun(@(i)'-',1:numel(Edge_idx));
    data.graph.EdgeColor            = tools.varrayfun(@(i)[0,0,0],1:numel(Edge_idx));
    data.graph.Marker               = [tools.arrayfun(@(i)'o',1:nbus),tools.arrayfun(@(i)'o',1:nbus)];
    data.graph.NodeColor            = zeros(2*nbus,3);
    data.graph.XData                = [data.graph.XData(1:nbus),data.graph.XData(1:nbus)];
    data.graph.YData                = [data.graph.YData(1:nbus),data.graph.YData(1:nbus)];

    
    axis off
    arrayfun(@(idx) labelnode(data.graph,idx,num2str(idx)),1:nbus)
    
    cmap = jet;
    switch main_Node
        case 'bus'
            data.graph.Marker               = [tools.arrayfun(@(i)'s',1:nbus),tools.arrayfun(@(i)'_',1:nbus)];
            data.graph.MarkerSize           = [10*ones(1,nbus),10*ones(1,nbus)];
            data.graph.ZData                = [ones(1,nbus),zeros(1,nbus)];
            data.graph.LineWidth(Edge_idx)  = 2;
            zlim([0,1.1])
            meanX = mean(data.graph.XData);
            meanY = mean(data.graph.YData);
            r = max(abs([data.graph.XData-meanX,data.graph.YData-meanY]));
            plot_circle([meanX,meanY],r*1.1)
            view(0,75)

            W = zeros(numel(Edge_idx),nbus);
            EndNodes = dara.G.Edges{:,'EndNodes'};
            for i = 1:numel(Edge_idx)
                yij = Y(EndNodes(i,1),EndNodes(i,2));
                W(i,EndNodes(i,1)) = yij;
                W(i,EndNodes(i,2)) = -yij;
            end

            
            data.setNheight = @(para,lim) set(data.graph,'ZData',[abs(para),zeros(1,nbus)]);
            data.setNcolor  = @(para,lim) set(data.graph,'NodeColor',[cmap(normalize(para,'range',[1,256]),:);zeros(nbus,3)]);
            data.setNsize   = @(para,lim) set(data.graph,'MarkerSize', [normalize(abs(para),'range',[10,20]),10*ones(1,nbus)]);
            
            data.setEcolor = @(para,lim) gset(data.graph,'EdgeColor',Edge_idx,reshape(para,[],3));
            data.setEwidth = @(para,lim) gset(data.graph,'LineWidth',Edge_idx,3*(abs(para)+1));

            data.setBrcolor = @(para,lim) gset(data.graph,'EdgeColor',~Edge_idx,reshape(para,[],3));
            data.setBrwidth = @(para,lim) gset(data.graph,'LineWidth',~Edge_idx,normalize(abs(para),'range',[1,5]));

        case 'component'
            data.digraph = set_quiver(data.graph,nbus);
            data.graph.LineStyle(Edge_idx)  = {':'};
            data.graph.LineWidth(Edge_idx)  = 0.01;
            zlim([-1.1,1])
            view(5,45)
            
            data.setHeight = @(para) set(data.digraph,'ZData',[zeros(1,nbus),para]);
            data.setNcolor = @(para) set(data.digraph,'NodeColor',[zeros(nbus,3);reshape(para,[],3)]);
            data.setNsize  = @(para) gset(data.digraph,'MarkerSize', nbus+1:2*nbus,10*(abs(para)+1));
            
            data.setEcolor = @(para) set(data.digraph,'EdgeColor',reshape(para,[],3));
            word = {'LineWidth','ArrowSize'}; ss = [3,6];
            data.setEwidth = @(para) arrayfun(@(i) set(data.digraph,word{i},ss(i)*(abs(para)+1)),1:2);

            data.setBrcolor = @(para) gset(data.graph,'EdgeColor',~Edge_idx,reshape(para,[],3));
            data.setBrwidth = @(para) gset(data.graph,'LineWidth',~Edge_idx,3*(abs(para+1)));
    end
    hold off
    
end

%bus mainのグラフプロット上にグレーの円盤を作成する関数
function plot_circle(Center,radius)
    hold on
    dd =500;
    [x,y] = meshgrid(linspace(Center(1)-radius,Center(1)+radius,dd),...
                     linspace(Center(2)-radius,Center(2)+radius,dd));
    z = zeros(dd,dd);
    z( ((x-Center(1)).^2 +  (y-Center(2)).^2) >radius^2) = nan;
    surf(x,y,z,'EdgeColor','none','FaceAlpha',0.1,'FaceColor','#7E2F8E');
end

%component mainのグラフプロットに電力の方向を表した矢印をプロット
function plt = set_quiver(g,nbus)
    hold on
    plt = plot(digraph([zeros(nbus),zeros(nbus);eye(nbus),zeros(nbus)]));
    plt.XData = g.XData;
    plt.YData = g.YData;
    plt.ZData = [zeros(1,nbus),1*ones(1,nbus)];
    plt.MarkerSize = ones(1,2*nbus);
    plt.EdgeColor = zeros(nbus,3);
    plt.Marker    = g.Marker;
    plt.NodeColor = [tools.varrayfun(@(i)[0      0      0     ],1:nbus);...
                     tools.varrayfun(@(i)[0.4660 0.6740 0.1880],1:nbus)];
    plt.LineWidth = ones(1,nbus);
    plt.ArrowSize = ones(1,nbus);
    plt.ArrowPosition = 0.75;
    
    g.ZData = zeros(1,2*nbus);
    g.MarkerSize = 10^(-3)*ones(1,2*nbus);
end