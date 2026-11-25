classdef GraphTimeEventData < event.EventData & auxiliary
% Data of the event TimeChanged of a graph: the sample it shows after set_time.
%
% A graph (GraphBase) raises TimeChanged and calls its TimeChangedFcn as fcn(G, data) with
% this object after set_time has drawn it (also when it moves with a linked graph, and at
% every frame of animate and export_video). Time is G.rv_t(Index), the time of the sample
% shown, which is the sample nearest to the time asked for.
%
% <@Examples>
% ```matlab
% G = res.plot_trajectory();
% G.TimeChangedFcn = @(G, data) title(G.ax(1), sprintf("t = %.2f s (sample %d)", data.Time, data.Index));
% addlistener(G, "TimeChanged", @(G, data) disp(data.Time));
% G.set_time(1.0);
% ```
%
% See also GraphBase, GraphBase.set_time

    properties (SetAccess = private)
        Time (1,1) double   % [s] Time of the sample shown.
        Index (1,1) double  % Index of the sample shown (i_time of the graph).
    end

    methods
        function obj = GraphTimeEventData(t, k)
        % Event data of the sample shown.
            arguments (Input)
                t (1,1) double  % [s] Time of the sample.
                k (1,1) double  % Index of the sample.
            end
            arguments (Output)
                obj  % The event data.
            end
            obj.Time  = t;
            obj.Index = k;
        end
    end
end
