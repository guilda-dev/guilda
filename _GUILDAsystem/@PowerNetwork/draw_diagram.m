function G = draw_diagram(obj,ax)
    arguments
        obj 
        ax  = axes('Parent',figure())
    end
    G = DrawerNetDiagram(obj);
    G.plot(obj.cv_Vequilibrium, ax);
end