function anime(obj,varargin)
error('開発中です。。。')
% %＊＊＊未実装＊＊＊
%     
%     option = inputParser;
%     option.CaseSensitive = false;
% 
%     addParameter(option, 'busNode_color_access' ,'Vabs');
%     addParameter(option, 'busNode_color_st'     ,false );
%     addParameter(option, 'busNode_color_map'    ,'hot' ); 
%     addParameter(option, 'busNode_size_access'  ,'Vabs');
%     addParameter(option, 'busNode_size_st'      ,false  );
% 
%     addParameter(option, 'busBar_Height_access' ,'Vabs');
%     addParameter(option, 'busBar_Height_st'     ,false );
%     addParameter(option, 'busBar_color_access'  ,'flat');
%     addParameter(option, 'busBar_color_st'      ,false );
%     addParameter(option, 'busBar_color_map'     ,'none');
%     addParameter(option, 'busBar_Width_access'  ,'flat');
%     addParameter(option, 'busBar_Width_st'      ,'flat');
% 
%     addParameter(option, 'Branch1_color_access'  ,'Iabs' );
%     addParameter(option, 'Branch1_color_st'      ,false  );
%     addParameter(option, 'Branch1_color_map'     ,'jet' );
%     addParameter(option, 'Branch1_Width_access'  ,'Iabs' );
%     addParameter(option, 'Branch1_Width_st'      ,false  );
% 
%     addParameter(option, 'Branch2_color_access'  ,'Iabs' );
%     addParameter(option, 'Branch2_color_st'      ,false  );
%     addParameter(option, 'Branch2_color_map'     ,'jet' );
%     addParameter(option, 'Branch2_Width_access'  ,'flat' );
%     addParameter(option, 'Branch2_Width_st'      ,false  );
% 
%     addParameter(option, 'compNode_color_access','omega');
%     addParameter(option, 'compNode_color_st'    ,true   );
%     addParameter(option, 'compNode_color_map'   ,'jet'  ); 
%     addParameter(option, 'compNode_size_access' ,'omega' );
%     addParameter(option, 'compNode_size_st'     ,true   );
% 
%     addParameter(option, 'compBar_Height_access','Iabs' );
%     addParameter(option, 'compBar_Height_st'    ,false  );
%     addParameter(option, 'compBar_color_access' ,'Iabs' );
%     addParameter(option, 'compBar_color_st'     ,false  );
%     addParameter(option, 'compBar_color_map'    ,'cool' );
%     addParameter(option, 'compBar_Width_access' ,'Iabs'    );
%     addParameter(option, 'compBar_Width_st'     ,false  );
% 
%     addParameter(option, 'figure_para'          ,'none'  );
%     addParameter(option, 'figure_LineWidth' , 2     );  
%     addParameter(option, 'figure_legend', false );
%     
%     addParameter(option, 'fps'       , 10    );   
%     addParameter(option, 'Visible'   , true  );
%     addParameter(option, 'save'      , true  );
%     addParameter(option, 'fpslim'    , [5,20]);
%     addParameter(option, 'timespan'  , 'sample',@(method) ismember(method, {'time', 'sample'}));
% 
%     parse(option, varargin{:});
%     option = option.Results;
%     
%     
%     option.time_resample =time_resample(obj,option);
% 
% 
%     fig_movie = figure('Visible',option.Visible,'WindowState','maximized');
%     option.scale = 1;    
%     
%     %下段の応答プロットを作成
%     none2para = {'busBar_Height_access','compBar_Width_access','compNode_color_access'};
%     if strcmp(option.figure_para,'none')
%         option.figure_para = tools.cellfun(@(c) option.(c),none2para);
%     end
%     [~,figdata]= obj.plot('para',option.figure_para,'plot',false,'para_unique',false,'legend',option.figure_legend);
%     fplot = @(access,bus_idx) arrayfun(@(idx) plot(obj.t,access(idx),'LineWidth',option.figure_LineWidth),bus_idx);
%     plt_fig = tools.arrayfun(@(idx) plot_module(figdata,fplot,idx),1:numel(figdata));
% 
% 
%     %レイアウトの決定
%     subplot('Position',[0,0.45,0.495,0.4])
%     graph_fig{1} = make_graph(obj,'bus');
%     subplot('Position',[0.25,0.43,0.001,0.001])
%     title('\bf{Focus on bus}','FontSize',40,'FontAngle','italic','Color','#7E2F8E')
%     subplot('Position',[0.505,0.45,0.495,0.4])
%     graph_fig{2} = make_graph(obj,'component');
%     subplot('Position',[0.75,0.43,0.001,0.001])
%     title('\bf{Focus on component}','FontSize',40,'FontAngle','italic','Color','#77AC30')
%     subplot('Position',[0,0.425,1,0.001])
%     axis off
%     yline(0,'LineWidth',2)
%     subplot('Position',[0.5,0.5,0.001,0.35])
%     axis off
%     xline(0,'LineStyle',':','LineWidth',2)
%     subplot('Position',[0.5,0.35,0.001,0.001])
%     title('\bf{Plotting System Responses}','FontSize',30)
%     sgtitle('\bf{Power system response}','FontSize',60,'FontAngle','italic')
%     subplot('Position',[0.5,0.43,0.001,0.001])
%     plt_time = title('\bf{Time:0s}','FontSize',25,'Color','#FF0000');
% 
%     dataset = organize_optionfield(obj,option,graph_fig{1}.Branch_idx);
%     
% 
%     disp('動画作成中．．．')
%     percent = 10;
%     tnew  = option.time_resample;
%     loops = numel(tnew);
%     Mdata(loops) = struct('cdata',[],'colormap',[]);
% 
%     for itr = 1:loops
%         cellfun(@(fig) set(fig,'Value',tnew(itr)) ,plt_fig);
%         set(plt_time,'String',['Time:',num2str(tnew(itr),'%2.1f'),'s']);
%          
%         graph_fig{1}.setNheight(dataset.busBar.Height.data(itr,:))
%         graph_fig{1}.setNcolor(dataset.busNode.color.data(itr,:,:))
%         graph_fig{1}.setNsize(dataset.busNode.size.data(itr,:))
%         graph_fig{1}.setEcolor(dataset.busBar.color.data(itr,:,:))
%         graph_fig{1}.setEwidth(dataset.busBar.Width.data(itr,:))
%         graph_fig{1}.setBrcolor(dataset.Branch1.color.data(itr,:,:))
%         graph_fig{1}.setBrwidth(dataset.Branch1.Width.data(itr,:))
% 
%         graph_fig{2}.setHeight(dataset.compBar.Height.data(itr,:))
%         graph_fig{2}.setNcolor(dataset.compNode.color.data(itr,:,:))
%         graph_fig{2}.setNsize(dataset.compNode.size.data(itr,:))
%         graph_fig{2}.setEcolor(dataset.compBar.color.data(itr,:,:))
%         graph_fig{2}.setEwidth(dataset.compBar.Width.data(itr,:))
%         graph_fig{2}.setBrcolor(dataset.Branch2.color.data(itr,:,:))
%         graph_fig{2}.setBrwidth(dataset.Branch2.Width.data(itr,:))
% 
%         drawnow limitrate
%         Mdata(itr) = getframe(fig_movie);
%         if itr/loops*100>percent
%             fprintf([num2str(percent),'％=>'])
%             percent = percent+10;
%         end
%     end
%     fprintf('100％\n')
%     close(fig_movie)
end
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%% option設定の整理 %%%%%%%%%%%%%%%%%%%%%%%
% 
% function dataset = organize_optionfield(class,option,Edges)
% 
%     fn_list         = fieldnames(option);
%     fn_list         = fn_list(tools.vcellfun(@(f) contains(f,'_'),fn_list));
%     dataset     = struct(); 
%     for idx = 1:numel(fn_list)
%         fn = split(fn_list{idx},'_');
%         if strcmp(fn{end},'access')
%             if contains(fn{1},'Branch')
%                 mat_data = reference_branch_para(class,option.(fn_list{idx}),Edges,option.([fn{1},'_',fn{2},'_st']));
%             else
%                 [~,temp]= class.plot('para',option.(fn_list{idx}),'plot',false,'para_unique',false,'legend',option.figure_legend);
%                 mat_data = nan(numel(class.t),numel(class.V));
%                 if numel(temp) ~=0
%                     for i = 1:numel(temp)
%                         if option.([fn{1},'_',fn{2},'_st'])
%                             mat_temp = tools.harrayfun(@(idx) temp(i).access(idx) - temp(i).st(idx),temp(i).bus_idx);
%                         else
%                             mat_temp = tools.harrayfun(@(idx) temp(i).access(idx),temp(i).bus_idx);
%                         end
%                         mat_data(:,reshape(temp(i).bus_idx,1,[])) = mat_temp;
%                     end
%                 end
%             end
%             mat_data = mat_data/max(abs(mat_data),[],'all');
%             mat_data = data_resample(class.t,mat_data,option);
%             if strcmp(fn{2},'color')
%                 cmap = fcolormap(option.([fn{1},'_color_map']));
%                 temp = nan(size(mat_data,1),size(mat_data,2),3);
%                 for i = 1:size(mat_data,1)
%                     for j = 1:size(mat_data,2)
%                         if isnan(mat_data(i,j))
%                             temp(i,j,:) = [0,0,0];
%                         else
%                             temp(i,j,:) = cmap(round(mat_data(i,j)*127+128),:);
%                         end
%                     end
%                 end
%             else
%                 mat_data(isnan(mat_data)) = 0.2;
%                 temp = mat_data*option.scale;
%             end
%             dataset.(fn{1}).(fn{2}).data = temp;
%         end
%     end
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%% branchのパラメータ %%%%%%%%%%%%%%%%%%%%%%%
% 
% function mat_data = reference_branch_para(class,name,Edges,st_tf)
%     dV = @(from,to) (class.V{to}{:,'real'}+1j*class.V{to}{:,'imag'}) - (class.V{from}{:,'real'}+1j*class.V{from}{:,'imag'}); 
%     dVst = @(from,to) class.net_data.bus{to,'V_equilibrium'} - class.net_data.bus{from,'V_equilibrium'}; 
%     Y  = @(from,to) class.net_data.admittance_matrix(from,to);
%     I  = @(from,to) Y(from,to)*dV(from,to);
%     Ist = @(from,to) Y(from,to)*dVst(from,to);
%     switch name
%         case {'I','Iabs'}
%             data = @(from,to) abs(I(from,to));
%              st  = @(from,to) abs(Ist(from,to));
%         case 'Iangle'
%             data = @(from,to) angle(I(from,to));
%              st  = @(from,to) angle(Ist(from,to));
%         case 'Ireal'
%             data = @(from,to) angle(I(from,to));
%              st  = @(from,to) angle(Ist(from,to));
%         case 'Iimag'
%             data = @(from,to) imag(I(from,to));
%              st  = @(from,to) imag(Ist(from,to));
%         case {'Y','Yabs'}
%             data = @(from,to) abs(Y(from,to))*ones(numel(class.t),1);
%              st  = @(from,to) 0;
%         case 'Yreal'
%             data = @(from,to) real(Y(from,to))*ones(numel(class.t),1);
%              st  = @(from,to) 0;
%         case 'Yimag'
%             data = @(from,to) imag(Y(from,to))*ones(numel(class.t),1);
%              st  = @(from,to) 0;
%         case 'flat'
%             data = @(from,to) ones(numel(class.t),1);
%              st  = @(from,to) 0;
%         otherwise
%             mat_data = reference_branch_para(class,'flat',Edges);
%             return
%     end
%     if st_tf
%         data = @(from,to) data(from,to)-st(from,to);
%     end
%     Edges = Edges(Edges(:,2)<=numel(class.V),:);
%     mat_data = tools.harrayfun(@(idx) data(Edges(idx,1),Edges(idx,2)),1:size(Edges,1));
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%% plot関連の関数 %%%%%%%%%%%%%%%%%%%%%%%
% 
% %応答プロットのための関数
% function plt = plot_module(data,fplot,idx)
%     subplot(3,numel(data),2*numel(data)+idx)
%     hold on
%     fplot(data(idx).access,data(idx).bus_idx);
%     data(idx).legend();
%     xlabel('Time(s)','FontSize',20)
%     ylabel(data(idx).title,'FontSize',20)
%     plt = xline(0);
%     hold off
% end
% 
% %networkの情報からグラフを作成する関数
% function data = make_graph(out,main_Node)
%     nbus = numel(out.V);
%     Y = out.net_data.admittance_matrix;
%     data = struct();
%     data.G = graph([Y~=0,eye(size(Y,1));eye(size(Y,1)),eye(size(Y,1))],'omitselfloops');
%     data.Branch_idx = data.G.Edges{:,'EndNodes'};
%     Edge_idx        = data.Branch_idx(:,2)>nbus;
%     data.graph = plot(data.G);
%     layout(data.graph,'force','WeightEffect','direct')
% 
%     data.graph.LineWidth            = ones(1,size(data.Branch_idx,1));
%     data.graph.LineWidth(Edge_idx)  = 4;
%     data.graph.LineStyle            = tools.arrayfun(@(i)'-',1:numel(Edge_idx));
%     data.graph.EdgeColor            = tools.varrayfun(@(i)[0,0,0],1:numel(Edge_idx));
%     data.graph.Marker               = [tools.arrayfun(@(i)'o',1:nbus),tools.arrayfun(@(i)'o',1:nbus)];
%     data.graph.NodeColor            = tools.varrayfun(@(i)[0      0      0     ],1:2*nbus);
%     data.graph.XData                = [data.graph.XData(1:nbus),data.graph.XData(1:nbus)];
%     data.graph.YData                = [data.graph.YData(1:nbus),data.graph.YData(1:nbus)];
% 
%     XL = [min(data.graph.XData),max(data.graph.XData)];
%     YL = [min(data.graph.YData),max(data.graph.YData)];
%     xran = [XL(1)*1.1-XL(2)*0.1,-XL(1)*0.1+XL(2)*1.1];
%     yran = [YL(1)*1.1-YL(2)*0.1,-YL(1)*0.1+YL(2)*1.1];
% 
%     axis off
%     arrayfun(@(idx) labelnode(data.graph,idx,num2str(idx)),1:nbus)
%     
% 
%     switch main_Node
%         case 'bus'
%             data.graph.Marker               = [tools.arrayfun(@(i)'o',1:nbus),tools.arrayfun(@(i)'_',1:nbus)];
%             data.graph.MarkerSize           = [10*ones(1,nbus),10*ones(1,nbus)];
%             data.graph.ZData                = [ones(1,nbus),zeros(1,nbus)];
%             data.graph.LineWidth(Edge_idx)  = 2;
%             maxran = max([diff(xran),diff(yran)])/1.75;
%             xlim([mean(xran)-maxran*1.1,mean(xran)+maxran*1.1])
%             ylim([mean(yran)-maxran*1.1,mean(yran)+maxran*1.1])
%             zlim([0,1.1])
%             plot_circle([mean(xran)-maxran,mean(xran)+maxran],[mean(yran)-maxran,mean(yran)+maxran])
%             view(0,75)
%             
%             data.setNheight = @(para) set(data.graph,'ZData',[abs(para),zeros(1,nbus)]);
%             data.setNcolor  = @(para) set(data.graph,'NodeColor',[reshape(para,[],3);zeros(nbus,3)]);
%             data.setNsize   = @(para) set(data.graph,'MarkerSize', [10*(abs(para)+1),0.1*ones(1,nbus)]);
%             
%             data.setEcolor = @(para) gset(data.graph,'EdgeColor',Edge_idx,reshape(para,[],3));
%             data.setEwidth = @(para) gset(data.graph,'LineWidth',Edge_idx,3*(abs(para)+1));
% 
%             data.setBrcolor = @(para) gset(data.graph,'EdgeColor',~Edge_idx,reshape(para,[],3));
%             data.setBrwidth = @(para) gset(data.graph,'LineWidth',~Edge_idx,3*(abs(para)+1));
% 
%         case 'component'
%             data.digraph = set_quiver(data.graph,nbus);
%             data.graph.LineStyle(Edge_idx)  = {':'};
%             data.graph.LineWidth(Edge_idx)  = 0.01;
%             xlim(xran)
%             ylim(yran)
%             zlim([-1.1,1])
%             view(5,45)
%             
%             data.setHeight = @(para) set(data.digraph,'ZData',[zeros(1,nbus),para]);
%             data.setNcolor = @(para) set(data.digraph,'NodeColor',[zeros(nbus,3);reshape(para,[],3)]);
%             data.setNsize  = @(para) gset(data.digraph,'MarkerSize', nbus+1:2*nbus,10*(abs(para)+1));
%             
%             data.setEcolor = @(para) set(data.digraph,'EdgeColor',reshape(para,[],3));
%             word = {'LineWidth','ArrowSize'}; ss = [3,6];
%             data.setEwidth = @(para) arrayfun(@(i) set(data.digraph,word{i},ss(i)*(abs(para)+1)),1:2);
% 
%             data.setBrcolor = @(para) gset(data.graph,'EdgeColor',~Edge_idx,reshape(para,[],3));
%             data.setBrwidth = @(para) gset(data.graph,'LineWidth',~Edge_idx,3*(abs(para+1)));
%     end
%     hold off
%     
% end
% 
% %bus mainのグラフプロット上にグレーの円盤を作成する関数
% function plot_circle(XLim,YLim)
%     hold on
%     dd =500;
%     [y,x] = meshgrid(linspace(XLim(1),XLim(2),dd),...
%                      linspace(YLim(1),YLim(2),dd));
%     [zr,zv] = meshgrid((1:dd)-dd/2,(1:dd)-dd/2);
%     zidx = (zr.^2+zv.^2)>(dd/2)^2;
%     z = zeros(dd,dd);
%     z(zidx)= nan ;
%     surf(x,y,z,'EdgeColor','none','FaceAlpha',0.1,'FaceColor','#7E2F8E');
% end
% 
% %component mainのグラフプロットに電力の方向を表した矢印をプロット
% function plt = set_quiver(g,nbus)
%     hold on
%     plt = plot(digraph([zeros(nbus),zeros(nbus);eye(nbus),zeros(nbus)]));
%     plt.XData = g.XData;
%     plt.YData = g.YData;
%     plt.ZData = [zeros(1,nbus),1*ones(1,nbus)];
%     plt.MarkerSize = ones(1,2*nbus);
%     plt.EdgeColor = zeros(nbus,3);
%     plt.Marker    = g.Marker;
%     plt.NodeColor = [tools.varrayfun(@(i)[0      0      0     ],1:nbus);...
%                      tools.varrayfun(@(i)[0.4660 0.6740 0.1880],1:nbus)];
%     plt.LineWidth = ones(1,nbus);
%     plt.ArrowSize = ones(1,nbus);
%     plt.ArrowPosition = 0.75;
%     
%     g.ZData = zeros(1,2*nbus);
%     g.MarkerSize = 10^(-3)*ones(1,2*nbus);
% end
% 
% function  gset(plt,name,idx,value)
%     if size(plt.(name),1) ~=1
%         plt.(name)(idx,:) = value;
%     else
%         plt.(name)(idx) = value;
%     end
% end
% 
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
% 
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
% 
% function cmat = fcolormap(name)
% switch name
%     case 'PM'
%         cmat = [ones(128,1)*[0 0.4470 0.7410];ones(128,1)*[0.8500 0.3250 0.0980]];
%     case 'none'
%         cmat = zeros(256,3);
%     otherwise
%         cmat = colormap(name);
% end
% end