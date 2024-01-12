function out = information(obj,varargin)
    %引数に与えられたネットワークのモデルのパラメータを調べる用の関数

    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'do_report', true);
    addParameter(p, 'plot_graph', false);
    addParameter(p, 'HTML'      , false);
    addParameter(p, 'export_tex_data', false);
    
    
    parse(p, varargin{:});
    options = p.Results;

    info = supporters.for_netinfo.InfoCenter(obj);
    if options.do_report
        info.fprintf
    end

    if options.plot_graph ~= 0
        if isgraphics( options.plot_graph )
            ax = options.plot_graph;
        else
            figure
            ax = gca;
        end
        g = supporters.for_graph.map(obj,ax);
        g.initialize;
        % g.set_Color_subject2CompType;

        cellfun(@(b) set(b,'marker', 'none' ), g.a_bus)
        cellfun(@(b) set(b,'size'  , 0.1    ), g.a_bus)
        cellfun(@(b) set(b,'Label' , []     ), g.a_bus)
        
        is_empty = tools.vcellfun(@(b) isa(b.component,'component.empty'), obj.a_bus);
        cellfun(@(c) set(c,'marker', 's'), g.a_component(is_empty));
        cellfun(@(c) set(c,'size'  , 7  ), g.a_component);
        cellfun(@(c) set(c,'ZData' , 0  ), g.a_component);
        cellfun(@(c) set(c,'Label' , [c.object.Tag,num2str(c.number)] ), g.a_component(~is_empty))

        cellfun(@(b) set(b,'width',2     ), g.a_branch)
        cellfun(@(b) set(b,'width',0.1   ), g.a_busline(~is_empty))
        cellfun(@(b) set(b,'style','none'), g.a_busline(is_empty))
        
        g.Graph.NodeLabelColor = [0,0,0];
        g.Graph.NodeFontSize = 5;
        g.remove_margin;
    end

    out = info.data;
end


