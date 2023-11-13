function [x,xcl,xcg,Vall,Iall] = organize_Xode(obj,xsys)

    nbus = numel(obj.network.a_bus);

    x = cell(nbus, 1);
    for i = 1:numel(obj.simulated_bus)
        x{obj.simulated_bus(i)} = xsys(obj.logimat.x(:,i));
    end

    xcl = cell( numel(obj.network.a_controller_local), 1);
    for i = 1:numel(obj.simulated_cl)
        xcl{obj.simulated_cl(i)} = xsys(obj.logimat.xcl(:,i));
    end
    
    xcg = cell( numel(obj.network.a_controller_global), 1);
    for i = 1:numel(obj.simulated_cg)
        xcg{obj.simulated_cg(i)} = xsys(obj.logimat.xcg(:,i));
    end
    

    Vall = zeros(2,nbus);
    Iall = zeros(2,nbus);

    Vpart = xsys(obj.logimat.V);
    Ipart = obj.Ymat * Vpart;

    Vall(:,obj.noreduced_bus) = reshape( Vpart, 2, []);
    Iall(:,obj.noreduced_bus) = reshape( Ipart, 2, []);
    
    Vall(:,obj.I0const_bus) = reshape( xsys(obj.logimat.I0const), 2, []);
    Iall(:,obj.V0const_bus) = reshape( xsys(obj.logimat.V0const), 2, []);

    % V = num2cell(Vall,1);
    % I = num2cell(Iall,1);
    
end