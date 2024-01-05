function refresh_graph_controller_marker_setter(app,data)
    if nargin<2
        data = app.net.information('do_report',false);
    end

    %各controlleのgraph設定tableに関して
    lcon = data.controller_local;
    gcon = data.controller_global;

    tab = [];
    if ~isempty(lcon)
        tab = [tab;lcon(:,'class')];
    end
    if ~isempty(gcon)
        tab = [tab;gcon(:,'class')];
    end
    

    if ~isempty(tab)
        variable = tools.varrayfun(@(b) string([num2str(b),'.',tab{b,1}]),(1:size(tab,1))');
        idx_input = false(size(variable));
        idx_observe = false(size(variable));
        color = cell(size(variable)); 
        color(:) = {'g'};
        app.graph_controller_switch_table.Data = table(variable,idx_input,idx_observe,color);
    end
end
%ok