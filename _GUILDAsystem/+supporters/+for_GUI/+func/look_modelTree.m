function out = look_modelTree(net, plot_switch, admittance_switch)
%plot_switch : 表示するグラフのブランチ上にアドミタンスの値を表示するかしないか。
% plot_switch = true  表示する
% plot_switch = false 表示しない


%%%%%%%%%%%%%%%%%パラメータ%%%%%%%%%%%%%%%%%%
%・Gen1axis
m_gen = 'o';
c_gen = '#D95319';%'red'
%・Load
m_load = 'square';
c_load = '#0072BD';%'blue'
%・non-unit
m_non = 'o';
c_non = '#7E2F8E';%'purple'
%・その他:
m_other = '^';
c_other ='#77AC30';%'green'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<2
    plot_switch = true;
end
if nargin<3
    admittance_switch = false;
end
idx = supporters.for_user.func.look_component_type(net);


Y = net.get_admittance_matrix;
%ブランチの重みづけにバグあり！！
g = graph(abs(triu(Y)),'upper','omitselfloops');
Ed = table2array(g.Edges);
weight = cell(size(Ed,1),1);
for itr=1:size(Ed,1)
    y = round(Y(double(Ed(itr,1)),(Ed(itr,2))),3,'significant');
    weight{itr} = num2str(y);
end 
nEd = normalize(Ed(:,3));


n_bus = numel(net.a_bus);
marker_tag = cell(n_bus,1);
marker_tag(idx.generator)= {m_gen};
marker_tag(idx.load     )= {m_load};
marker_tag(idx.non_unit )= {m_non};
marker_tag(~(idx.generator|idx.load|idx.non_unit))= {m_other};

Mcolor_tag = cell(n_bus,1);
Mcolor_tag(idx.generator) = {c_gen};
Mcolor_tag(idx.load     ) = {c_load};
Mcolor_tag(idx.non_unit ) = {c_non};
Mcolor_tag(~(idx.generator|idx.load|idx.non_unit)) = {c_other};

Msize_tag = zeros(n_bus,1);
Msize_tag(idx.generator ) = round(90/sqrt(n_bus));
Msize_tag(idx.load      ) = round(60/sqrt(n_bus));
Msize_tag(idx.non_unit  ) = round(45/sqrt(n_bus));
Msize_tag(~(idx.generator|idx.load|idx.non_unit)) = round(40/sqrt(n_bus));

Nsize_tag = zeros(n_bus,1);
Nsize_tag(idx.generator ) = 15;
Nsize_tag(idx.load      ) = 10;
Nsize_tag(idx.non_unit  ) = 10;
Nsize_tag(~(idx.generator|idx.load|idx.non_unit)) = 10;

Mcolor_num=validatecolor(Mcolor_tag,'multiple');

if plot_switch
    if admittance_switch
        plt_net = plot(g,'EdgeLabel',weight,'NodeFontSize',Nsize_tag,'LineWidth',2*(0.01-min(nEd)+nEd),'EdgeColor','k','Marker',marker_tag,'NodeColor',Mcolor_num,'MarkerSize',Msize_tag);
    else
%        plt_net = plot(g,'NodeFontSize',Nsize_tag,'LineWidth',2*(0.01-min(nEd)+nEd),'EdgeColor','k','Marker',marker_tag,'NodeColor',Mcolor_tag,'MarkerSize',Msize_tag);
        plt_net = plot(g,'NodeFontSize',Nsize_tag,'LineWidth',2*(0.01-min(nEd)+nEd),'EdgeColor','k','Marker',marker_tag,'NodeColor',Mcolor_num,'MarkerSize',Msize_tag);
    end
    set(plt_net,'Interpreter','none')
    plt_xlim = [min(plt_net.XData),max(plt_net.XData)];
    plt_ylim = [min(plt_net.YData),max(plt_net.YData)];
    if plt_xlim(1)==plt_xlim(2)
        plt_x = plt_xlim(1)+(-1:0.5:1);
    else
        plt_x = plt_xlim(1):0.25*(plt_xlim(2)-plt_xlim(1)):plt_xlim(2);
    end
    if plt_ylim(1)==plt_ylim(2)
        plt_y = plt_ylim(1)-30;
    else
        plt_y = plt_ylim(1)-0.2*(plt_ylim(2)-plt_ylim(1));
    end
    plt_net = text(plt_x(1),plt_y,'●：発電機バス',"Color",[0.8500 0.3250 0.0980],"FontSize",10);
    plt_net = text(plt_x(2),plt_y,'■：負荷バス',"Color",[0 0.4470 0.7410],"FontSize",10);
    plt_net = text(plt_x(3),plt_y,'●：non-unitバス',"Color",[0.4940 0.1840 0.5560],"FontSize",10);
    plt_net = text(plt_x(4),plt_y,'▲：dynamic load バス',"Color",[0.4660 0.6740 0.1880],"FontSize",10);
end

out.g = g;
out.Nword_size = Nsize_tag;
out.Nshape     = marker_tag;
out.Ncolor     = Mcolor_tag;
out.Nsize      = Msize_tag;
out.Eword      = weight;
out.Ewidth     = nEd;

end