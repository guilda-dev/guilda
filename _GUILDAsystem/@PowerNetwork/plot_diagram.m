function G = plot_diagram(obj,ax)
% Draw the network diagram of buses, branches and components.
%
% <@Examples>
% ```matlab
% G = net.plot_diagram();
% ```
%
% See also DrawerNetDiagram
%
% <@Group> Queries and display
    arguments (Input)
        obj 
        ax  = axes('Parent',figure())   % Axes to draw in (default: new axes in a new figure).
    end
    arguments (Output)
        G   % DrawerNetDiagram object of the drawing.
    end
    G = DrawerNetDiagram(obj,ax);
end