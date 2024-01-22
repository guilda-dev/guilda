function out = information(obj,varargin)
    %引数に与えられたネットワークのモデルのパラメータを調べる用の関数

    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'do_report', true);
    addParameter(p, 'graph'  , false);
    addParameter(p, 'HTML'   , false);
    addParameter(p, 'TeX'    , false);
    addParameter(p, 'TeXpath', []   );
    
    parse(p, varargin{:});
    options = p.Results;

    info = supporters.for_netinfo.InfoCenter(obj);
    if options.do_report
        info.fprintf
    end

    if options.graph ~= 0
        if isgraphics( options.graph )
            ax = options.graph;
        else
            figure
            ax = gca;
        end
        g = supporters.for_graph.map(obj,ax);
        g.initialize;
        g.set_Color_subject2CompType;
    end

    out = info.data;

    if options.TeX || ~isempty(options.TeXpath)
        supporters.for_netinfo.TeX.main(obj,out);
    end
end


