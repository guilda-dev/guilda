function g = plot_diagram(obj, varargin)
%PLOT_DIAGRAM  Display a network diagram of the power system.
%
%   g = net.plot_diagram()        opens a figure with two side-by-side
%   views of the network graph:
%     Left  – "Focus on bus"       : nodes coloured by bus type
%                                    (slack / PV / PQ)
%     Right – "Focus on component" : nodes coloured by component type
%                                    (generator / load / …)
%
%   g = net.plot_diagram('Visible', false)
%   creates the figure without displaying it.
%
%   The returned object g is a supporters.for_graph.plot instance whose
%   g.graph{1} and g.graph{2} properties hold the underlying map objects
%   for each panel.

    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'Visible', true);
    parse(p, varargin{:});

    g = supporters.for_graph.plot(obj, p.Results.Visible);
end
