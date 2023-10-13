function out = information(obj,varargin)
    %引数に与えられたネットワークのモデルのパラメータを調べる用の関数

    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'do_report', true);
    addParameter(p, 'plot_graph', false);
    addParameter(p, 'HTML'      , false);
    addParameter(p, 'graphVisible'   , 'wheather_plot_or_not');
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
        g.set_Color_subject2CompType;
        g.remove_margin;
    end

    out = info.data;
end


