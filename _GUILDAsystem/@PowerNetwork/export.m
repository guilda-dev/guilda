function [data,Graph] = export(obj,options)
    arguments
        obj 
        options.disp  (1,1) logical = true;
        options.graph (1,1) logical = false;
        options.latex (1,1) logical = false;
    end
    info = supporters.for_netinfo.InfoCenter(obj);
    if options.disp
        info.fprintf; 
    end
    if options.graph
        Graph = supporters.for_graph.map(obj,gca);
        Graph.initialize;
        Graph.set_Color_subject2CompType;
    end
    data = info.data;
    if options.TeX
        supporters.for_netinfo.TeX.main(obj,data);
    end
end