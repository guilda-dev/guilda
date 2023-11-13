function set_parameter(obj)
    
    % 母線電圧 =0 and 母線電流 =0 
    % 母線電圧 =0 and 母線電流~=0 
    % 母線電圧~=0 and 母線電流 =0 
    % 母線電圧~=0 and 母線電流~=0 

    net = obj.network;

    % シミュレーションで使う各条件のindexを取得
    V0bus = unique( union(obj.additional_V0bus(:)' ,obj.fault.get_bus_list   ), 'sorted'); % 母線電圧=0の制を受ける母線番号の取得
    I0bus = unique( union(obj.additional_I0bus(:)' ,obj.parallel.get_bus_list), 'sorted'); % 母線電流=0の制を受ける母線番号の取得

    no_empty   = find( ~tools.hcellfun(@(b) isa(b.component,'component.empty'), net.a_bus) ); %non-unit-busではない母線番号
    is_pararell   = setdiff(no_empty,I0bus);
    no_reduced = union(is_pararell,V0bus); %non-unit-busの母線から解列した母線を除いた母線番号
    
    obj.noreduced_bus = setdiff(no_reduced, V0bus);
    if obj.isCalculated_disconnected_mac
        obj.simulated_bus = no_empty;
    else
        obj.simulated_bus = is_pararell;
    end

    obj.I0const_bus = intersect(I0bus, obj.simulated_bus);
    obj.V0const_bus = intersect(V0bus, is_pararell);


    % 接続している機器のindexを取得
    connect_branch = find( tools.hcellfun(@(b) strcmp(b.parallel,'on'), net.a_branch) );
    obj.simulated_cl = find( tools.hcellfun(@(c) strcmp(c.parallel,'on'), net.a_controller_local) );
    obj.simulated_cg = find( tools.hcellfun(@(c) strcmp(c.parallel,'on'), net.a_controller_global));


    % アドミタンス行列を定義
    [Y, obj.Ymat_all] = net.get_admittance_matrix([],connect_branch);
    [~, Ymat_temp,~, Vmat_reproduce] = net.reduce_admittance_matrix(Y, no_reduced);
    idx_admittance = ismember(kron(no_reduced(:),[1;1]), obj.noreduced_bus);
    obj.Ymat = Ymat_temp(idx_admittance, idx_admittance);
    obj.Vmat_reproduce = Vmat_reproduce(:, idx_admittance);
    obj.Imat_reproduce = zeros(size(obj.Vmat_reproduce));
    obj.Imat_reproduce(idx_admittance,:) = eye(sum(idx_admittance));


    logi{1} = fmac(tools.cellfun(@(b)b.component,net.a_bus), obj.simulated_bus );
    logi{2} = fcon(net.a_controller_local                  , obj.simulated_cl  );
    logi{3} = fcon(net.a_controller_global                 , obj.simulated_cg  );
    temp = logical(blkdiag(logi{:}));

    index_x  =   ones(1,numel(obj.simulated_bus));
    index_cl = 2*ones(1,size(logi{2},2));
    index_cg = 3*ones(1,size(logi{3},2));
    index_VI = 4*ones(1,numel(obj.simulated_bus));
    index_VI(ismember(obj.simulated_bus, obj.I0const_bus)) = 5;
    index_VI(ismember(obj.simulated_bus, obj.V0const_bus)) = 6;
    index_mac = [index_x;index_VI];
    index = [index_mac(:)', index_cl, index_cg];

    obj.logimat.x      = temp(:,index==1);
    obj.logimat.xcl    = temp(:,index==2);
    obj.logimat.xcg    = temp(:,index==3);
    obj.logimat.V      = any( temp(:,index==4), 2);
    obj.logimat.I0const = any( temp(:,index==5), 2);
    obj.logimat.V0const = any( temp(:,index==6), 2);

    function out = fcon(data,index)
        f = tools.arrayfun(@(i) true(data{i}.get_nx,1), index);
        out = blkdiag(f{:});
    end

    function out = fmac(data,index)
        f = tools.arrayfun(@(i) blkdiag(true(data{i}.get_nx,1),true(2,1)), index);
        out = blkdiag(f{:});
    end
    
end