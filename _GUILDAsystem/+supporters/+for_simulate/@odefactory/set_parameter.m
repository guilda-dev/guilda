function set_parameter(obj)
    
    % 母線電圧 =0 and 母線電流 =0 
    % 母線電圧 =0 and 母線電流~=0 
    % 母線電圧~=0 and 母線電流 =0 
    % 母線電圧~=0 and 母線電流~=0 

    net = obj.network;

    obj.V0const_bus = union(obj.additional_V0bus(:)' ,obj.fault.get_bus_list   ); % 母線電圧=0の制を受ける母線番号の取得
    obj.I0const_bus = union(obj.additional_I0bus(:)' ,obj.parallel.get_bus_list); % 母線電流=0の制を受ける母線番号の取得

    no_empty   = find( ~tools.hcellfun(@(b) isa(b.component,'component.empty'), net.a_bus) );
    no_reduced = setdiff(no_empty,obj.I0const_bus);
    
    if obj.isCalculated_disconnected_mac
        obj.simulated_bus = no_empty;
    else
        obj.simulated_bus = no_reduced;
    end

    c_logic_state = cell(numel(obj.simulated_bus),1);
    c_logic_flow  = cell(numel(obj.simulated_bus),1);
    for i = obj.simulated_bus
        nx = net.a_bus{i}.component.get_nx;
        c_logic_state{i} = [ i*ones(nx,1);  zeros(2,1)];
        c_logic_flow{i}  = [  zeros(nx,1); i*ones(2,1)];
    end

    connect_branch = find( tools.hcellfun(@(b) strcmp(b.parallel,'on'), net.a_branch) );
    connect_cl     = find( tools.hcellfun(@(c) strcmp(c.parallel,'on'), net.a_controller_local) );
    connect_cg     = find( tools.hcellfun(@(c) strcmp(c.parallel,'on'), net.a_controller_global) );

    [Y, obj.Ymat_all] = net.get_admittance_matrix([],connect_branch);
    [~, obj.Ymat,~, obj.Ymat_reproduce] = net.reduce_admittance_matrix(Y, obj.noreduced_bus);

    logi{1} = f(tools.cellfun(@(b)b.component,net.a_bus), obj.noreduced_bus );
    logi{2} = f(net.a_controller_local                  , connect_cl        );
    logi{3} = f(net.a_controller_global                 , connect_cg        );
    logi{4} = true(length(obj.Ymat),1);
    logi{5} = true(obj.I0const_bus,1);
    logi{6} = true(obj.V0const_bus,1);

    temp = blkdiag(logi{:});
    index = tools.harrayfun(@(i)i*ones(1,size(logi{i},2)), 1:6);
    obj.logimat.x      = temp(:,index==1);
    obj.logimat.xcl    = temp(:,index==2);
    obj.logimat.xcg    = temp(:,index==3);
    obj.logimat.V      = temp(:,index==4);
    obj.logimat.Iconst = temp(:,index==5);
    obj.logimat.Vconst = temp(:,index==6);

    function out = f(data,index)
        f = tools.arrayfun(@(i) true(data{i}.get_nx,1), index);
        out = blkdiag(f{:});
    end
    
end