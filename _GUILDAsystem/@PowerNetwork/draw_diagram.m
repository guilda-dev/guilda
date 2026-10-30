function G = draw_diagram(obj,ax)
% Draw the network diagram of buses, branches and components.
%
% <@Examples>
% ```matlab
% G = net.draw_diagram();
% ```
%
% See also DrawerNetDiagram
    arguments
        obj 
        ax  = axes('Parent',figure())   % Axes to draw in (default: new axes in a new figure).
    end
    arguments (Output)
        G   % DrawerNetDiagram object of the drawing.
    end
    G = DrawerNetDiagram(obj,ax);
end