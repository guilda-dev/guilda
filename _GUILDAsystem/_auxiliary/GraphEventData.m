classdef GraphEventData < event.EventData
% Data of the event ElementClicked of a graph: the element that was clicked.
%
% A graph (GraphBase) raises ElementClicked and calls its ElementClickedFcn as
% fcn(G, data) with this object when an element is clicked. The fields are those of the
% row of the element in G.tab_element.
%
% <@Examples>
% ```matlab
% G = net.plot_diagram();
% G.ElementClickedFcn = @(G, data) disp(data.Tag + " (" + data.Kind + ")");
% addlistener(G, "ElementClicked", @(G, data) G.select(data.Tag));
% ```
%
% See also GraphBase

    properties (SetAccess = private)
        Tag  (1,1) string   % Tag of the element.
        Kind (1,1) string   % Kind of the element (e.g. "bus", "node").
        Index (1,1) double  % Position of the element in the vectors of its kind.
    end

    methods
        function obj = GraphEventData(s_tag, s_kind, i_index)
        % Event data of a clicked element.
            arguments (Input)
                s_tag (1,1) string    % Tag of the element.
                s_kind (1,1) string   % Kind of the element.
                i_index (1,1) double  % Position in the vectors of its kind.
            end
            arguments (Output)
                obj  % The event data.
            end
            obj.Tag   = s_tag;
            obj.Kind  = s_kind;
            obj.Index = i_index;
        end
    end
end
