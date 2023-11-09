function [x0,const0] = get_initial(obj,x0,xcl0,xcg0,V0,I0,Vvir0)

    x0   = x0(  obj.logical.x  );
    xcl0 = xcl0(obj.logical.xcl);
    xcg0 = xcg0(obj.logical.xcg);

    net = obj.network;
    V0comp = V0(1:2:end)+1j*V0(2:2:end);
    I0comp = I0(1:2:end)+1j*I0(2:2:end);
    for i = 1:numel(net.a_bus)
        if isempty(x0) || any(isnan(x0(obj.logimat.x(:,i))))
            warning('off')
            c = net.a_bus{i}.component.copy;
            x0(obj.logimat.x(:,i)) = c.set_equilibrium(V0comp(i),I0comp(i));
            warning('on')
        end
    end
    for i = 1:numel(net.a_controller_local)
        if isempty(xcl0) || any(isnan(xcl0(obj.logimat.xcl(:,i))))
            xcl0(obj.logimat.xcl(:,i)) = net.a_controller_local{i}.get_x0;
        end
    end
    for i = 1:numel(net.a_controller_global)
        if isempty(xcg0) || any(isnan(xcg0(obj.logimat.xcg(:,i))))
            xcg0(obj.logimat.xcg(:,i)) = net.a_controller_global{i}.get_x0;
        end
    end
    
    x0 = [x0;xcl0;xcg0];

    Vvir0(isnan(Vvir0))=0;
    const0 = [V0(   obj.logical.V     ) ;...
              I0(   obj.logical.Vconst) ;...
              Vvir0(obj.logical.Iconst) ];
end