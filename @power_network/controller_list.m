function controller_list(obj,fig)

    num_lcon = numel(obj.a_controller_local);
    num_gcon = numel(obj.a_controller_global);
    if num_lcon + num_gcon == 0
        warning('No Controller!!')
        return
    end
    name_lcon = tools.varrayfun(@(i) {[class(obj.a_controller_local{i} ),num2str(i)]},  1:num_lcon);
    name_gcon = tools.varrayfun(@(i) {[class(obj.a_controller_global{i}),num2str(i)]}, 1:num_gcon);

    
    if nargin<2
        fig = uifigure('Position',[200,200,800,400]);
    end

    panel = uipanel(fig,'Position',[20,80,400,300]);
    
    pop = uicontrol(fig,...
                    'Style'   , 'popupmenu',...
                    'Position', [85,20,250,30],...
                    'String'  , [name_lcon; name_gcon]);
    radio = uibuttongroup(fig,'Position',[450 20 300 40],'BorderType','none');
    subradio{1} = uitogglebutton(radio,'Position',[30 5 110 30],'Text','index observe');
    subradio{2} = uitogglebutton(radio,'Position',[160 5 110 30],'Text','index input');
    
    ax = uiaxes(fig,'Position',[430,20,350,360]);
    ax.InnerPosition = [430,20,350,360];
    graph = tools.graph.map_component_for_UI(obj,ax);
    align([graphax btn],'center','middle');
    
    color  = graph.Graph.NodeColor;
    controller_selection([],[],obj,panel,graph,pop,radio,color)

    radio.SelectionChangedFcn = @(src,eve) index_selection(src,eve,obj,graph,pop,radio,color);
    pop.Callback   = @(src,eve) controller_selection(src,eve,obj,panel,graph,pop,radio,color);
end

function controller_selection(~,~,net,panel,graph,pop,radio,color)
    val = pop.Value;
    num_lcon = numel(net.a_controller_local);
    if val <= num_lcon
        con = net.a_controller_local{val};
    else
        con = net.a_controller_global{val-num_lcon};
    end

    if ismember('set_parameter',methods(con))
        con.set_parameter(panel) 
    end
    index_selection([],[],net,graph,pop,radio,color)
end

function index_selection(~,~,net,graph,pop,radio,color)
    val = pop.Value;
    num_lcon = numel(net.a_controller_local);
    if val <= num_lcon
        con = net.a_controller_local{val};
    else
        con = net.a_controller_global{val-num_lcon};
    end

    if strcmp( radio.SelectedObject.Text, 'index observe')
        idx = con.index_observe;
    else
        idx = con.index_input;
    end
    
    nbus = numel(net.a_bus);
    color(idx+nbus,:) = ones(numel(idx),1) * [1,0,0];
    graph.Graph.NodeColor = color;
end
