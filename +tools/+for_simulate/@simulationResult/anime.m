function anime(obj,varargin)
%error('開発中です。。。')
%＊＊＊未実装＊＊＊
    
    option = inputParser;
    option.CaseSensitive = false;

    addParameter(option, 'Val_Bus_Size'         ,15);
    addParameter(option, 'Val_Bus_Height'       ,'Vabs');
    addParameter(option, 'Val_Bus_Color'        ,'Vabs');
    addParameter(option, 'base_Bus_Size'        ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
    addParameter(option, 'base_Bus_Height'      ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
    addParameter(option, 'base_Bus_Color'       ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
    addParameter(option, 'Val_Component_Size'   ,'M');
    addParameter(option, 'Val_Component_Height' ,'P_pm');
    addParameter(option, 'Val_Component_Color'  ,'omega');
    addParameter(option, 'base_Component_Size'  ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
    addParameter(option, 'base_Component_Height','zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
    addParameter(option, 'base_Component_Color' ,'zero', @(method) ismember(method, {'zero','equilibrium','finalVal'}));
    
    
    addParameter(option, 'figure_LineWidth' , 2     );  
    addParameter(option, 'figure_legend', false );
    
    %addParameter(option, 'fps'       , 10    ); 
    %addParameter(option, 'fpslim'    , [5,20]);
    %addParameter(option, 'timespan'  , 'sample',@(method) ismember(method, {'time', 'sample'}));

    addParameter(option, 'time_span'  , 0.05 );
    addParameter(option, 'save'      , false  );

    parse(option, varargin{:});
    option = option.Results;

    ntime = numel(obj.t);
    nbus  = numel(obj.net.a_bus);

    
    
    
    %option.time_resample =time_resample(obj,option);

    fig_movie = figure('Visible',"on",'WindowState','maximized');
    %レイアウトの決定
    ax{1} = subplot('Position',[0,0.45,0.495,0.4]);
    graph_fig{1} = tools.graph.map_bus_for_anime(obj.net,ax{1});
    graph_fig{1}.ColorMap = turbo;
    view(0,50)
    subplot('Position',[0.25,0.43,0.001,0.001]);
    title('\bf{Focus on bus}','FontSize',40,'FontAngle','italic','Color','#7E2F8E')
    ax{2} = subplot('Position',[0.505,0.45,0.495,0.4]);
    graph_fig{2} = tools.graph.map_component_for_anime(obj.net,ax{2});
    graph_fig{2}.ColorMap = turbo;
    subplot('Position',[0.75,0.43,0.001,0.001])
    title('\bf{Focus on component}','FontSize',40,'FontAngle','italic','Color','#77AC30')
    subplot('Position',[0,0.425,1,0.001])
    axis off
    yline(0,'LineWidth',2)
    subplot('Position',[0.5,0.5,0.001,0.35])
    axis off
    xline(0,'LineStyle',':','LineWidth',2)
    subplot('Position',[0.5,0.35,0.001,0.001])
    title('\bf{Plotting System Responses}','FontSize',30)
    sgtitle('Power system response','FontSize',60,'FontAngle','italic')
    subplot('Position',[0.5,0.43,0.001,0.001])
    plt_time = title('\bf{Time:0s}','FontSize',25,'Color','#FF0000');    


    %下段の応答プロットを作成
    fieldnames = append({'Val_Bus_','Val_Component_'},{'Size','Height','Color'}');
    fieldnames = fieldnames(:);
    paras = tools.hcellfun(@(field) {option.(field)}, fieldnames);
    [~,~,dataset] = obj.plot('para',paras,'para_unique', false,'plot',false);
    
    is_not_flat = tools.harrayfun(@(i) ~contains(dataset(i).title,{'flat','sign','parameter'}),1:6);
    
    idx_not_flat = find(is_not_flat);
    [~, ia_para, ic_para] = unique(paras(is_not_flat));
    ia_para = idx_not_flat(ia_para);

    cnt_subplot = 0;
    xlin  = cell(6,1); 
    Cbar = cell(6,1);
    for i = 1:6
        field = fieldnames{i};
        base  = option.(strrep(field, 'Val', 'base'));
        title_name = cut_(strrep(field,'Val_',''));
        
        if ismember(i, ia_para)
            id_para = find(ic_para == find(ia_para==i));
            title_word = tools.harrayfun(@(j) ['"',cut_(strrep(fieldnames{j},'Val_','')),'", '], id_para);
            cnt_subplot =cnt_subplot+1;
            subplot(3,numel(ia_para),2*numel(ia_para)+cnt_subplot)
            hold on
            subtitle(title_word(1:end-2),'FontSize',15)
            xlabel('Time(s)','FontSize',15)
            ylabel(dataset(i).title,'FontSize',15)
            xlin{i} = xline(0);
        end
        data = nan(nbus, ntime);

        for idx = 1:nbus
            if ismember(idx, dataset(i).bus_idx)
                response = dataset(i).access(idx);
                switch base
                    case 'equilibrium'
                        response = response - dataset(i).st(idx);
                    case 'finalVal'
                        response = response - response(end);
                end
                if is_not_flat(i)
                    plot(obj.t,response,'LineWidth',option.figure_LineWidth)
                end
                data(idx,:) = reshape(response,1,[]);
            elseif is_not_flat(i)
                plot(nan,nan)
            end
        end

        if contains(field,'Bus')
            idx_Gfig = 1;
        else
            idx_Gfig = 2;
        end

        if contains(field,'Height')
            if contains(field,'Bus')
                data = graph_fig{idx_Gfig}.normalize( data, [0.1,1],false);
            else
                data = graph_fig{idx_Gfig}.normalize( data, [-1,1],true);
            end
            data(isnan(data)) = 0;
        elseif contains(field,'Size')
            data = graph_fig{idx_Gfig}.normalize( data, [10,40], false);
            data(isnan(data)) = 10;
        elseif contains(field,'Color')
            [temp_data,lim] = graph_fig{idx_Gfig}.normalize( data, [1,256],false);
            data = round( temp_data);
            Cbar{i} = colorbar;
            Cbar{i}.Parent.Colormap = graph_fig{idx_Gfig}.ColorMap;
            clim(lim + [-1,1]*1e-10);
        end
        option.(field) = data;

        
        disp(['(',num2str(i),'/6): Data processing for parameter of ',title_name ,' is complete.'])
    end



    %初期設定
    a_BusColor = zeros(nbus,3);
    a_CompColor = zeros(nbus,3);

    graph_fig{1}.Graph.MarkerSize(1:nbus)   = option.Val_Bus_Size(:,1);
    graph_fig{1}.Graph.ZData(1:nbus)        = option.Val_Bus_Height(:,1);
    c = option.Val_Bus_Color(:,1);
    a_BusColor(~isnan(c),:) = graph_fig{1}.ColorMap(c(~isnan(c)),:);
    graph_fig{1}.Graph.NodeColor(1:nbus,:)  = a_BusColor;
    graph_fig{2}.Graph.MarkerSize(nbus+(1:nbus))   = option.Val_Component_Size(:,1);
    graph_fig{2}.Graph.ZData(nbus+(1:nbus))        = option.Val_Component_Height(:,1);
    c = option.Val_Component_Color(:,1);
    a_CompColor(~isnan(c),:) = graph_fig{2}.ColorMap(c(~isnan(c)),:);
    graph_fig{2}.Graph.NodeColor(nbus+(1:nbus),:)  = a_CompColor;

    % 地絡のデータを整理
    fault_time = tools.vcellfun(@(sol) sol{end}.x(end),obj.sols);
    fault_marker_fig1 = [];
    fault_marker_fig2 = [];
    fault_text_fig1 = [];
    fault_text_fig2 = [];
    idx_current_fault = 1;
    mark_fault = @(ax,x,y,z) scatter3(...
                    ax,x,y,z,800,'filled',"hexagram",...
                    'MarkerEdgeColor','k','MarkerFaceColor',"y");
    text_fault = @(ax,x,y,z,word) text(...
                        ax,x,y,z,'fault',...
                        'FontSize',20,...
                        'FontWeight','bold',...
                        'Color', 'r');


    drawnow 
    disp('Graph layout setup complete.')


    idx_time = resample(obj.t, option.time_span);
    
    pause(1.0)

    disp('making animation．．．')

    loops = numel(idx_time);

    if option.save
        Mdata(loops) = struct('cdata',[],'colormap',[]);
    end

    tic
    t_pre = 0;
    for m = 1:loops
        
        itr = idx_time(m);

        if is_not_flat(1)
            %Bus Size
            graph_fig{1}.Graph.MarkerSize(1:nbus)   = option.Val_Bus_Size(:,itr);
        end

        if is_not_flat(2)
            %Bus Height
            graph_fig{1}.Graph.ZData(1:nbus)        = option.Val_Bus_Height(:,itr);
        end

        if is_not_flat(3)
            %Bus Color
            c = option.Val_Bus_Color(:,itr);
            a_BusColor(~isnan(c),:) = graph_fig{1}.ColorMap(c(~isnan(c)),:);
            graph_fig{1}.Graph.NodeColor(1:nbus,:)  = a_BusColor;
        end
        
        if is_not_flat(4)
            %Component Size
            graph_fig{2}.Graph.MarkerSize(nbus+(1:nbus))   = option.Val_Component_Size(:,itr);
        end

        if is_not_flat(5)
            %Componrnt Height
            graph_fig{2}.Graph.ZData(nbus+(1:nbus))        = option.Val_Component_Height(:,itr);
        end
        
        if is_not_flat(6)
            %Component Color
            c = option.Val_Component_Color(:,itr);
            a_CompColor(~isnan(c),:) = graph_fig{2}.ColorMap(c(~isnan(c)),:);
            graph_fig{2}.Graph.NodeColor(nbus+(1:nbus),:)  = a_CompColor;
        end

        if obj.t(itr) > fault_time(idx_current_fault)
            idx_current_fault = idx_current_fault +1;
            delete(fault_text_fig1)
            delete(fault_text_fig2)
            delete(fault_marker_fig1)
            delete(fault_marker_fig2)
            fault_bus = obj.fault_bus{idx_current_fault};

            xfig1 = graph_fig{1}.Graph.XData(fault_bus);
            yfig1 = graph_fig{1}.Graph.YData(fault_bus);
            zfig1 = graph_fig{1}.Graph.ZData(fault_bus);
            xfig2 = graph_fig{2}.Graph.XData(fault_bus);
            yfig2 = graph_fig{2}.Graph.YData(fault_bus);
            zfig2 = graph_fig{2}.Graph.ZData(fault_bus);

            hold(graph_fig{1}.Graph.Parent, 'on')
            fault_marker_fig1 = mark_fault(graph_fig{1}.Graph.Parent, xfig1, yfig1, zfig1);
            fault_text_fig1   = text_fault(graph_fig{1}.Graph.Parent, xfig1, yfig1, zfig1,'fault');
            hold(graph_fig{2}.Graph.Parent, 'on')
            fault_marker_fig2 = mark_fault(graph_fig{2}.Graph.Parent, xfig2, yfig2, zfig2);
            fault_text_fig2   = text_fault(graph_fig{2}.Graph.Parent, xfig2, yfig2, zfig2,'fault');
        end


        t_now = obj.t(itr);
        if m < loops
            t_next    = obj.t(itr+1);
            while t_next > t_now
                arrayfun(@(idx) set(xlin{idx},'Value',t_now) ,find(is_not_flat));
                set(plt_time,'String',['Time:',num2str(t_now,'%2.2f'),'s']);
                t_now = t_now + 0.2;
                drawnow limitrate
                if ~option.save
                    pause(max( (t_now-t_pre)/2 - toc ,0))
                    t_pre = t_now;
                    tic
                end
            end
        else
            arrayfun(@(idx) set(xlin{idx},'Value',t_now) ,find(is_not_flat));
            set(plt_time,'String',['Time:',num2str(t_now,'%2.2f'),'s']);
            [~] = toc;
        end

        if option.save
            Mdata(itr) = getframe(fig_movie);
        end
    end
end

function name = cut_(name)
    name(name=='_') = ' ';
end

function idx = resample(time, time_span)
    idx = 1;
    while true
        i = find(time > time_span+time(idx(end)),1,'first');
        if isempty(i)
            if idx(end) ~= numel(time)
                idx = [idx;numel(time)];
            end
            return
        else
            idx = [idx;i];
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%% plot関連の関数 %%%%%%%%%%%%%%%%%%%%%%%


% % データのリサンプリング
% function datanew = data_resample(t,data,option)
%     tnew = option.time_resample;
%     sd  = size(data);
%     sd(1) = numel(tnew);
%     datanew = zeros(sd);
%     for i = 1:numel(tnew)
%         before = find(t<=tnew(i),1,'last');
%         after = find(t>=tnew(i),1,"first");
%         if before == after
%             datanew(i,:) = data(i,:);
%         else
%             datanew(i,:) = ( data(before,:)*(tnew(i)-t(before))+...
%                              data(after ,:)*(t(after)-tnew(i)) )...
%                             ./(t(after)-t(before));
%         end
%     end
% end

% function tnew = time_resample(obj,option)
%     switch option.timespan
%         case 'time'
%             tnew = linspace(obj.t(1),obj.t(end),option.fps*obj.t(end)+1);
%         case 'sample'
%             tnew = obj.t;
%             idx =1;
%             tlim = 1./option.fpslim;
%             while idx<numel(tnew)
%                 dt = tnew(idx+1)-tnew(idx);
%                 if dt>(tlim(1)+10^(-10))
%                     tnew = [tnew(1:idx);tnew(idx)+tlim(1);tnew(idx+1:end)];
%                 elseif any(tnew(idx+1:end)-tnew(idx)<tlim(2))
%                     tnew((tnew-tnew(idx)<tlim(2))&(tnew-tnew(idx)>0)) = [];
%                 end
%                 idx = idx+1;
%             end
%     end
% end
