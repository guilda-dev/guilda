classdef animator < matlab.mixin.SetGet
    properties
        
        style  = 'style3';

        height = 'P';
        color  = 'P';
        size   = 'P_abs';

        height_base = 0;% double値/'equilibrium'/'final' 
        color_base  = 0;% double値/'equilibrium'/'final' 
        size_base   = 0;% double値/'equilibrium'/'final' 

        height_index
        color_index
        size_index

        fig
        pltData   = cell(3,1);
        pltAxes   = cell(3,1);
        graphData 
        graphAxes         
        XlineData = cell(3,1);
        faultPlot

        time_list
        TimeBoard
        current_time = 0;
        controller
    end

    properties(SetAccess=protected)
        net
        out
        

        DataSet_height
        DataSet_color
        DataSet_size

        faultdata

    end

    methods

        function obj = animator(out,net,varargin)
            obj.net = net;
            obj.out = out;
            obj.time_list = (out.t(1):0.001:out.t(end))';
            
            nf = numel(obj.out.option.fault);
            obj.faultdata.time = tools.varrayfun(@(i) out.option.fault.data(i).time(:)', 1:nf);
            obj.faultdata.index= tools.arrayfun(@(i) out.option.fault.data(i).index, 1:nf);
            obj.faultPlot = repmat({false},1,nf);

            obj.make_figure

            para = {'style','size','height','color'};
            option = inputParser;
            option.CaseSensitive = false;
            cellfun(@(p) addParameter(option, p ,obj.(p)), para);
            cellfun(@(p) addParameter(option,[p,'_base'], obj.([p,'_base'])), para(2:4))
            parse(option, varargin{:});
            option = option.Results;
            cellfun(@(p) set(obj, p ,option.(p)), para);
            obj.current_time = obj.time_list(1);

            obj.controller = supporters.for_simulate.sol.animator_controller(obj);
            
        end


        function make_figure(obj)
            obj.fig = figure('Position',[200,200,1000,500]);
            obj.fig.DeleteFcn = @(~,~) delete(obj.controller);

            ax  = subplot('Position',[0.4,0.9,0.59,0.09]);
            ax.Visible = 'off';
            xlim(ax,[-1,1])
            text(ax,0,0,'Network Graph', 'FontSize',30,'FontWeight','bold','HorizontalAlignment','center')
            obj.TimeBoard = text(ax,0,-1,'Time:0(s)','FontSize',20,'FontWeight','bold','HorizontalAlignment','center');
            
            obj.graphAxes  = subplot('Position',[0.4,0.1,0.59,0.75]);
            
            obj.pltAxes{1} = subplot('Position',[0.05,0.08,0.3,0.25]);
            obj.pltAxes{2} = subplot('Position',[0.05,0.38,0.3,0.25]);
            obj.pltAxes{3} = subplot('Position',[0.05,0.68,0.3,0.25]);
  
            cellfun(@(ax) set(ax.XAxis,'Visible','off'), obj.pltAxes([2,3]));

            op = {'FontWeight','bold','FontSize',12};
            subtitle(obj.pltAxes{1}, 'Height parameter',op{:})
            subtitle(obj.pltAxes{2}, 'Color parameter' ,op{:})
            subtitle(obj.pltAxes{3}, 'Size parameter'  ,op{:})
            
            op = {'FontWeight','bold','FontSize',12,'Interpreter','latex'};
            ylabel(obj.pltAxes{1}, "$"+string(obj.height)+"$",op{:})
            ylabel(obj.pltAxes{2}, "$"+string(obj.color) +"$",op{:})
            ylabel(obj.pltAxes{3}, "$"+string(obj.size)  +"$",op{:})
            xlabel(obj.pltAxes{1}, 'Time(s)' )

            for i = 1:3
                ax = obj.pltAxes{i};
                grid(ax,'on')
                tlim = obj.out.t([1,end]);
                xlim(ax,tlim)
            end
        end

        function set.style(obj,s)
            obj.style = s;
            switch s
                case {'style1',1}
                    obj.graphData = supporters.for_graph.map_forAnime1(obj.net, obj.graphAxes);%#ok
                    obj.graphData.ZLim = [0,1.05];%#ok
                case {'style2',2}
                    obj.graphData = supporters.for_graph.map_forAnime2(obj.net, obj.graphAxes);%#ok
                    obj.graphData.ZLim = inf;%#ok
                case {'style3',3}
                    obj.graphData = supporters.for_graph.map_forAnime3(obj.net, obj.graphAxes);%#ok
                    obj.graphData.ZLim = [-1.05,1.05];%#ok
            end
            obj.organize('height');
            obj.organize('color');
            obj.organize('size');
            obj.update_graph
            obj.faultdata.Graphindex = tools.cellfun(@(f) tools.vcellfun(@(b) b.index, obj.graphData.a_bus(f)),obj.faultdata.index);%#ok
        end
       

        function set.height(obj,data)
            obj.height = data;
            ylabel(obj.pltAxes{1}, "$"+string(obj.height)+"$")%#ok
            obj.organize('height');
        end

        function set.color(obj,data)
            obj.color = data;
            ylabel(obj.pltAxes{2}, "$"+string(obj.color)+"$")%#ok
            obj.organize('color');
        end
        function set.size(obj,data)
            obj.size = data;
            ylabel(obj.pltAxes{3}, "$"+string(obj.size)+"$")%#ok
            obj.organize('size');
        end

        function set.current_time(obj,t)
            obj.current_time = t(1);
            obj.update_graph(t)
        end

        function update_graph(obj,tidx,flag)
            if nargin == 1
                tidx = obj.current_time;
            end

            if nargin < 3 || isempty(flag)
                tidx = find(obj.time_list<=tidx,1,'last');
            end

            obj.graphData.Graph.ZData(obj.height_index)       = obj.DataSet_height(tidx,:);
            ctemp = obj.DataSet_color(tidx,:);
            obj.graphData.Graph.NodeColor(obj.color_index,:) = obj.graphData.ColorMap(ctemp,:);
            obj.graphData.Graph.MarkerSize(obj.size_index)   = obj.DataSet_size(tidx,:);


            tval = obj.time_list(tidx);
            obj.TimeBoard.String = ['Time:',num2str(tval,'%.2f'),'(s)'];
            for i = 1:3
                xl = obj.XlineData{i};
                if isgraphics(xl)
                    xl.Value = tval;
                else
                    hold(obj.pltAxes{i},'on')
                    obj.XlineData{i} = xline(obj.pltAxes{i},tval,'k');
                    hold(obj.pltAxes{i},'off')
                end
            end
            obj.mark_fault(tval)
        end

        function dataset = organize(obj,type)

            para = obj.(type);
            
            if isnumeric(para)
                if numel(para) == numel(obj.net.a_bus)
                    obj.(['DataSet_',type]) = ones(numel(obj.time_list),numel(obj.net.a_bus)) * para(:)';
                elseif numel(para) == 1
                    obj.(['DataSet_',type]) = para * ones(numel(obj.time_list),numel(obj.net.a_bus));
                else
                    error(' ')
                end
                ax = obj.pltAxes{strcmp({'height','color','size'},type)};
                x = mean(ax.XLim);
                y = mean(ax.YLim);
                text(ax,x,y, 'No data', 'FontSize',15, 'HorizontalAlignment','center')
                
                if string(obj.style)=="style1" || string(obj.style)=="1"
                    obj.([type,'_index']) = tools.vcellfun(@(e) e.index, obj.graphData.a_bus);
                else
                    obj.([type,'_index']) = tools.vcellfun(@(e) e.index, obj.graphData.a_component);
                end
                return
            end

            [~,~,data] = obj.out.plot('para',para,'bus_idx','all_bus','para_unique', false,'plot',false,'setting_update',false);
            
            switch obj.([type,'_base'])
                case 'final'
                    dataset = tools.harrayfun(@(i) myspline(obj.out.t, data.access(i) ,obj.time_list), data.bus_idx);
                    dataset = dataset - dataset(end,:);
                case 'equilibrium'
                    dataset = tools.harrayfun(@(i) myspline(obj.out.t, data.access(i) - data.st(i), obj.time_list), data.bus_idx);
                otherwise
                    dataset = tools.harrayfun(@(i) myspline(obj.out.t, data.access(i), obj.time_list) - obj.([type,'_base']), data.bus_idx);
            end

            switch type
                case 'height'
                    hold(obj.pltAxes{1},'on')
                    obj.pltData{1} =  tools.arrayfun(@(i) plot(obj.pltAxes{1}, obj.out.t, data.access(i)), data.bus_idx);
                    hold(obj.pltAxes{1},'off')
                    switch obj.style
                        case {'style1',1}
                            dataset = obj.graphData.normalize(dataset,'mean',0,'base',1/2,'scale',1/4,'range',[0,1]);
                        case {'style2',2}
                            dataset = obj.graphData.normalize(dataset,'mean',0,'base',0,'scale',1,'range',[0,1]);
                        case {'style3',3}
                            dataset = obj.graphData.normalize(dataset,'mean',0,'base',0,'scale',1/2.5,'range',[-1,1]);
                    end
                    obj.DataSet_height = dataset;
                case 'color'
                    hold(obj.pltAxes{2},'on')
                    obj.pltData{2} =  tools.arrayfun(@(i) plot(obj.pltAxes{2}, obj.out.t, data.access(i)), data.bus_idx);
                    hold(obj.pltAxes{2},'off')
                    tempdata = obj.graphData.normalize(dataset);
                    lim = [min(dataset,[],'all'),max(dataset,[],'all')];
                    ColorBar = colorbar(obj.graphAxes);
                    ColorBar.Parent.Colormap = obj.graphData.ColorMap;
                    clim(obj.graphAxes, lim + [-1,1]*1e-10);

                    obj.DataSet_color = obj.graphData.val2color(tempdata);
                case 'size'
                    hold(obj.pltAxes{3},'on')
                    obj.pltData{3} =  tools.arrayfun(@(i) plot(obj.pltAxes{3}, obj.out.t, data.access(i)), data.bus_idx);
                    hold(obj.pltAxes{3},'off')
                    obj.DataSet_size = obj.graphData.normalize(dataset,'base',15,'scale',7,'range',[1,30]);
            end


            switch obj.style
                case {'style1',1}
                    obj.([type,'_index']) = tools.vcellfun(@(e) e.index, obj.graphData.a_bus(data.bus_idx));
                case {'style2',2}
                    obj.([type,'_index']) = tools.vcellfun(@(e) e.index, obj.graphData.a_component(data.bus_idx));
                case {'style3',3}
                    obj.([type,'_index']) = tools.vcellfun(@(e) e.index, obj.graphData.a_component(data.bus_idx));
            end

        end

        function mark_fault(obj,t)
            t = obj.faultdata.time-t;
            idx = t(:,1).*t(:,2) <= 0;
            for i = 1:numel(idx)
                if idx(i) && ~isgraphics(obj.faultPlot{i})
                    hold(obj.graphAxes,'on' );
                    fidx = obj.faultdata.Graphindex{i};
                    nf = numel(fidx);
                    obj.faultPlot{i} = plot(obj.graphAxes,graph(eye(nf),'omitselfloops'), ...
                                'Marker'    ,'hexagram'            , ...
                                'NodeColor' ,[0.74,0.57,0.18]      , ...
                                'LineStyle' ,'none'                , ...
                                'MarkerSize',20                    , ...
                                'NodeLabel' ,repmat({'Fault'},1,nf), ...
                                'NodeFontSize',15                  , ...
                                'NodeFontWeight','bold'            , ...
                                'NodeLabelColor',[0.74,0.57,0.18]);
                    obj.faultPlot{i}.XData = obj.graphData.Graph.XData(fidx);
                    obj.faultPlot{i}.YData = obj.graphData.Graph.YData(fidx);
                    obj.faultPlot{i}.ZData = obj.graphData.Graph.ZData(fidx);
                    %obj.faultPlot{i} = scatter3(x,y,z,1000,'filled','Marker','hexagram','MarkerFaceColor','y','MarkerEdgeColor','k');
                    hold(obj.graphAxes,'off');
                elseif ~idx(i) && isgraphics(obj.faultPlot{i})
                    delete(obj.faultPlot{i})
                end
            end
        end

    end
end

function yq = myspline(x,y,xq)
    [~,idx,~] = unique(x);
    nonidx = setdiff(1:numel(x),idx);
    x(nonidx) = x(nonidx)+(1+rand(1,numel(nonidx)))*1e-15;
    yq = interp1(x,y,xq,'pchip');
end

% 
% function anime(obj,net,varargin)
% %error('開発中です。。。')
% %＊＊＊未実装＊＊＊
% 
%     option = inputParser;
%     option.CaseSensitive = false;
%     addParameter(option, 'style' ,15);
%     addParameter(option, 'size'  ,15);
%     addParameter(option, 'height',15);
%     addParameter(option, 'color' ,15);
% 
%     addParameter(option, 'Val_Bus_Size'         ,15);
%     addParameter(option, 'Val_Bus_Height'       ,'Vimag');
%     addParameter(option, 'Val_Bus_Color'        ,'Vimag');
%     addParameter(option, 'base_Bus_Size'        ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
%     addParameter(option, 'base_Bus_Height'      ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
%     addParameter(option, 'base_Bus_Color'       ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
%     addParameter(option, 'Val_Component_Size'   ,'M');
%     addParameter(option, 'Val_Component_Height' ,'P_pm');
%     addParameter(option, 'Val_Component_Color'  ,'omega');
%     addParameter(option, 'base_Component_Size'  ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
%     addParameter(option, 'base_Component_Height','zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
%     addParameter(option, 'base_Component_Color' ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
% 
% 
%     addParameter(option, 'figure_LineWidth' , 2     );  
%     addParameter(option, 'figure_legend', false );
% 
%     %addParameter(option, 'fps'       , 10    ); 
%     %addParameter(option, 'fpslim'    , [5,20]);
%     %addParameter(option, 'timespan'  , 'sample',@(method) ismember(method, {'time', 'sample'}));
% 
%     addParameter(option, 'time_span'  , 0.05 );
%     addParameter(option, 'save'      , false  );
% 
%     parse(option, varargin{:});
%     option = option.Results;
% 
%     ntime = numel(obj.t);
%     nbus  = size(obj.net_data.bus,1);
% 
% 
% 
% 
%     %option.time_resample =time_resample(obj,option);
% 
%     fig_movie = figure('Visible',"on",'WindowState','maximized');
%     %レイアウトの決定
%     ax{1} = subplot('Position',[0,0.45,0.495,0.4]);
%     graph_fig{1} = supporters.for_graph.map_forAnimeL(net,ax{1});
%     graph_fig{1}.ColorMap = turbo;
%     view(0,50)
%     subplot('Position',[0.25,0.43,0.001,0.001]);
%     %title('\bf{Focus on bus}','FontSize',40,'FontAngle','italic','Color','#7E2F8E')
%     ax{2} = subplot('Position',[0.505,0.45,0.495,0.4]);
%     graph_fig{2} = supporters.for_graph.map_forAnimeR(net,ax{2});
%     graph_fig{2}.ColorMap = turbo;
%     subplot('Position',[0.75,0.43,0.001,0.001])
%     %title('\bf{Focus on component}','FontSize',40,'FontAngle','italic','Color','#77AC30')
%     subplot('Position',[0,0.425,1,0.001])
%     axis off
%     yline(0,'LineWidth',2)
%     subplot('Position',[0.5,0.5,0.001,0.35])
%     axis off
%     xline(0,'LineStyle',':','LineWidth',2)
%     subplot('Position',[0.5,0.35,0.001,0.001])
%     title('\bf{Plotting System Responses}','FontSize',30)
%     sgtitle('Power system response','FontSize',60,'FontAngle','italic')
%     subplot('Position',[0.5,0.43,0.001,0.001])
%     plt_time = title('\bf{Time:0s}','FontSize',25,'Color','#FF0000');    
% 
% 
%     %下段の応答プロットを作成
%     fieldnames = append({'Val_Bus_','Val_Component_'},{'Size','Height','Color'}');
%     fieldnames = fieldnames(:);
%     paras = tools.hcellfun(@(field) {option.(field)}, fieldnames);
%     [~,~,dataset] = obj.plot('para',paras,'bus_idx','all_bus','para_unique', false,'plot',false,'setting_update',false);
% 
%     is_not_flat = tools.harrayfun(@(i) ~contains(dataset(i).title,{'flat','sign','parameter'}),1:6);
% 
%     idx_not_flat = find(is_not_flat);
%     [~, ia_para, ic_para] = unique(paras(is_not_flat));
%     ia_para = idx_not_flat(ia_para);
% 
%     cnt_subplot = 0;
%     xlin  = cell(6,1); 
%     Cbar = cell(6,1);
%     for i = 1:6
%         field = fieldnames{i};
%         base  = option.(strrep(field, 'Val', 'base'));
%         title_name = cut_(strrep(field,'Val_',''));
% 
%         if ismember(i, ia_para)
%             id_para = find(ic_para == find(ia_para==i));
%             title_word = tools.harrayfun(@(j) ['"',cut_(strrep(fieldnames{j},'Val_','')),'", '], id_para);
%             cnt_subplot =cnt_subplot+1;
%             subplot(3,numel(ia_para),2*numel(ia_para)+cnt_subplot)
%             hold on
%             subtitle(title_word(1:end-2),'FontSize',15)
%             xlabel('Time(s)','FontSize',15)
%             ylabel(dataset(i).title,'FontSize',15)
%             xlin{i} = xline(0);
%         end
%         data = nan(nbus, ntime);
% 
%         for idx = 1:nbus
%             if ismember(idx, dataset(i).bus_idx)
%                 response = dataset(i).access(idx);
%                 switch base
%                     case 'equilibrium'
%                         response = response - dataset(i).st(idx);
%                     case 'finalVal'
%                         response = response - response(end);
%                 end
%                 if is_not_flat(i)
%                     plot(obj.t,response,'LineWidth',option.figure_LineWidth)
%                 end
%                 data(idx,:) = reshape(response,1,[]);
%             elseif is_not_flat(i)
%                 plot(nan,nan)
%             end
%         end
% 
%         if contains(field,'Bus')
%             idx_Gfig = 1;
%         else
%             idx_Gfig = 2;
%         end
% 
%         if contains(field,'Height')
%             if contains(field,'Bus')
%                 data = graph_fig{idx_Gfig}.normalize( data, 'base',1/2,'scale',1/5,'range',[0,1]);
%                 graph_fig{idx_Gfig}.ZLim = [0,1];
%             else
%                 data = graph_fig{idx_Gfig}.normalize( data, 'base',0  ,'scale',1/2.5,'range',[-1,1]);
%                 graph_fig{idx_Gfig}.ZLim = [-1,1];
%             end
%             data(isnan(data)) = 0;
%         elseif contains(field,'Size')
%             data = graph_fig{idx_Gfig}.normalize( data, 'base',25,'scale',6,'range',[10,40]);
%             data(isnan(data)) = 10;
%         elseif contains(field,'Color')
%             temp_data = graph_fig{idx_Gfig}.normalize(data);
%             lim = [min(data,[],'all'),max(data,[],'all')];
%             data = graph_fig{idx_Gfig}.val2color(temp_data);
%             Cbar{i} = colorbar;
%             Cbar{i}.Parent.Colormap = graph_fig{idx_Gfig}.ColorMap;
%             clim(lim + [-1,1]*1e-10);
%         end
%         option.(field) = data;
% 
% 
%         disp(['(',num2str(i),'/6): Data processing for parameter of ',title_name ,' is complete.'])
%     end
% 
% 
% 
%     %初期設定
%     a_BusColor = zeros(nbus,3);
%     a_CompColor = zeros(nbus,3);
% 
%     graph_fig{1}.Graph.MarkerSize(1:nbus)   = option.Val_Bus_Size(:,1);
%     graph_fig{1}.Graph.ZData(1:nbus)        = option.Val_Bus_Height(:,1);
%     c = option.Val_Bus_Color(:,1);
%     a_BusColor(~isnan(c),:) = graph_fig{1}.ColorMap(c(~isnan(c)),:);
%     graph_fig{1}.Graph.NodeColor(1:nbus,:)  = a_BusColor;
%     graph_fig{2}.Graph.MarkerSize(nbus+(1:nbus))   = option.Val_Component_Size(:,1);
%     graph_fig{2}.Graph.ZData(nbus+(1:nbus))        = option.Val_Component_Height(:,1);
%     c = option.Val_Component_Color(:,1);
%     a_CompColor(~isnan(c),:) = graph_fig{2}.ColorMap(c(~isnan(c)),:);
%     graph_fig{2}.Graph.NodeColor(nbus+(1:nbus),:)  = a_CompColor;
% 
%     % 地絡のデータを整理
%     fault_time = tools.vcellfun(@(sol) sol.x(end),obj.sols);
%     fault_marker_fig1 = [];
%     fault_marker_fig2 = [];
%     fault_text_fig1 = [];
%     fault_text_fig2 = [];
%     idx_current_fault = 1;
%     mark_fault = @(ax,x,y,z) scatter3(...
%                     ax,x,y,z,800,'filled',"hexagram",...
%                     'MarkerEdgeColor','k','MarkerFaceColor',"y");
%     text_fault = @(ax,x,y,z,word) text(...
%                         ax,x,y,z,'fault',...
%                         'FontSize',20,...
%                         'FontWeight','bold',...
%                         'Color', 'r');
% 
% 
%     drawnow 
%     disp('Graph layout setup complete.')
% 
% 
%     idx_time = resample(obj.t, option.time_span);
% 
%     pause(1.0)
% 
%     disp('making animation．．．')
% 
%     loops = numel(idx_time);
% 
%     if option.save
%         Mdata(loops) = struct('cdata',[],'colormap',[]);
%     end
% 
%     tic
%     t_pre = 0;
%     for m = 1:loops
% 
%         itr = idx_time(m);
% 
%         if is_not_flat(1)
%             %Bus Size
%             graph_fig{1}.Graph.MarkerSize(1:nbus)   = option.Val_Bus_Size(:,itr);
%         end
% 
%         if is_not_flat(2)
%             %Bus Height
%             graph_fig{1}.Graph.ZData(1:nbus)        = option.Val_Bus_Height(:,itr);
%         end
% 
%         if is_not_flat(3)
%             %Bus Color
%             c = option.Val_Bus_Color(:,itr);
%             a_BusColor(~isnan(c),:) = graph_fig{1}.ColorMap(c(~isnan(c)),:);
%             graph_fig{1}.Graph.NodeColor(1:nbus,:)  = a_BusColor;
%         end
% 
%         if is_not_flat(4)
%             %Component Size
%             graph_fig{2}.Graph.MarkerSize(nbus+(1:nbus))   = option.Val_Component_Size(:,itr);
%         end
% 
%         if is_not_flat(5)
%             %Componrnt Height
%             graph_fig{2}.Graph.ZData(nbus+(1:nbus))        = option.Val_Component_Height(:,itr);
%         end
% 
%         if is_not_flat(6)
%             %Component Color
%             c = option.Val_Component_Color(:,itr);
%             a_CompColor(~isnan(c),:) = graph_fig{2}.ColorMap(c(~isnan(c)),:);
%             graph_fig{2}.Graph.NodeColor(nbus+(1:nbus),:)  = a_CompColor;
%         end
% 
%         if obj.t(itr) > fault_time(idx_current_fault)
%             idx_current_fault = idx_current_fault +1;
%             delete(fault_text_fig1)
%             delete(fault_text_fig2)
%             delete(fault_marker_fig1)
%             delete(fault_marker_fig2)
%             fault_bus = obj.fault_bus{idx_current_fault};
% 
%             xfig1 = graph_fig{1}.Graph.XData(fault_bus);
%             yfig1 = graph_fig{1}.Graph.YData(fault_bus);
%             zfig1 = graph_fig{1}.Graph.ZData(fault_bus);
%             xfig2 = graph_fig{2}.Graph.XData(fault_bus);
%             yfig2 = graph_fig{2}.Graph.YData(fault_bus);
%             zfig2 = graph_fig{2}.Graph.ZData(fault_bus);
% 
%             hold(graph_fig{1}.Graph.Parent, 'on')
%             fault_marker_fig1 = mark_fault(graph_fig{1}.Graph.Parent, xfig1, yfig1, zfig1);
%             fault_text_fig1   = text_fault(graph_fig{1}.Graph.Parent, xfig1, yfig1, zfig1,'fault');
%             hold(graph_fig{2}.Graph.Parent, 'on')
%             fault_marker_fig2 = mark_fault(graph_fig{2}.Graph.Parent, xfig2, yfig2, zfig2);
%             fault_text_fig2   = text_fault(graph_fig{2}.Graph.Parent, xfig2, yfig2, zfig2,'fault');
%         end
% 
% 
%         t_now = obj.t(itr);
%         if m < loops
%             t_next    = obj.t(itr+1);
%             while t_next > t_now
%                 arrayfun(@(idx) set(xlin{idx},'Value',t_now) ,find(is_not_flat));
%                 set(plt_time,'String',['Time:',num2str(t_now,'%2.2f'),'s']);
%                 t_now = t_now + 0.2;
%                 drawnow limitrate
%                 if ~option.save
%                     pause(max( (t_now-t_pre)/2 - toc ,0))
%                     t_pre = t_now;
%                     tic
%                 end
%             end
%         else
%             arrayfun(@(idx) set(xlin{idx},'Value',t_now) ,find(is_not_flat));
%             set(plt_time,'String',['Time:',num2str(t_now,'%2.2f'),'s']);
%             [~] = toc;
%         end
% 
%         if option.save
%             Mdata(itr) = getframe(fig_movie);
%         end
%     end
% end
% 
% function name = cut_(name)
%     name(name=='_') = ' ';
% end

