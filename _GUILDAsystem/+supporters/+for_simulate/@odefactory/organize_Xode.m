function [x,xcl,xcg,V,I] = organize_Xode(obj,xsys)

    nbus = numel(obj.network.a_bus);
    ncl  = numel(obj.network.a_controller_local);
    ncg  = numel(obj.network.a_controller_global);

    x = cell(nbus,1);
    V = cell(nbus,1);
    I = cell(nbus,1);

    xcl = cell(ncl,1);
    xcg = cell(ncg,1);

    v = xsys(obj.logimat.V);
    Vmat = reshape(          v, 2, []);
    Imat = reshape( obj.Ymat*v, 2, []);

    for i = obj.noreduced_bus
        x{i} = xsys(obj.logimat.x(:,i));
        V{i} = Vmat(:,i);
        I{i} = Imat(:,i);
    end

    for i = 1:numel(obj.V0const_bus)
        idx = obj.V0const_bus(i);
        x{idx} = xsys(obj.logimat.x(:,i));
        V{idx} = Vmat(:,i);
        I{idx} = Imat(:,i);
    end

    for i = 1:numel(obj.noreduced_bus)
        idx = obj.noreduced_bus(i);
        x{idx} = xsys(obj.logimat.x(:,i));
        V{idx} = Vmat(:,i);
        I{idx} = Imat(:,i);
    end
end