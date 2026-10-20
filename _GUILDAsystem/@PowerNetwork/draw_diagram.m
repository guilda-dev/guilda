function G = draw_diagram(obj,ax)
% <@Desc>
% Draws a network diagram of the power system structure on a MATLAB axes.
% <@Role>
% User Interface
% <@Abst>
% Creates a DrawerNetDiagram instance and renders the power network graph.
% <@Signatures>
% [
%   "G = net.draw_diagram()",
%   "G = net.draw_diagram(ax)"
% ]
% <@varargin>
% [
%   {
%     "Name": "ax",
%     "Type": "matlab.graphics.axis.Axes",
%     "Description": "Axes object to draw on.",
%     "Required": false,
%     "Default": "new axes in a new figure"
%   }
% ]
% <@varargout>
% [
%   {
%     "Name": "G",
%     "Type": "DrawerNetDiagram",
%     "Description": "DrawerNetDiagram instance for the rendered network."
%   }
% ]
    arguments
        obj 
        ax  = axes('Parent',figure())
    end
    G = DrawerNetDiagram(obj,ax);
end