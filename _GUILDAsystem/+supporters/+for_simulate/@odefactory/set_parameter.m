function set_parameter(obj)
net = obj.network;

%      地絡(V=0), 解列(I=0), non-unit
% G1 :     true,     true,     true    
% G2 :     true,    false,     true
% G3 :    false,     true,     true
% G4 :    false,    false,     true
% G5 :     true,     true,    false
% G6 :     true,    false,    false
% G7 :    false,     true,    false
% G8 :    false,    false,    false


% 解列機器の状態を計算する (obj.isCalculated_disconnected_mac = true)
%
%   ・状態の計算を行う番号(obj.simulated_bus) : G5,G6,G7,G8
%   ・I=0の代数変数の番号(obj.I0const_bus)　　: G5,G7 --> 機器から母線へのIが0となるVvirtualを変数とする
%   ・V=0の代数変数の番号(obj.V0const_bus)　　: G1,G5 --> 機器から地面に流れてくIを変数とする
%   ・アドミタンス行列に含む番号(idx_Y)        : G1,G2,G5,G6,G8
%   ・縮約しない母線の番号(obj.noreduced_bus) : G8
%

% 解列機器の状態を計算しない (obj.isCalculated_disconnected_mac = false)
%
%   ・状態の計算を行う番号(obj.simulated_bus) : G6,G8
%   ・I=0の代数変数の番号(obj.I0const_bus)　　: []    --> 機器から母線へのIが0となるVvirtualを変数とする
%   ・V=0の代数変数の番号(obj.V0const_bus)　　: G1,G5 --> 機器から地面に流れてくIを変数とする
%   ・アドミタンス行列に含む番号(idx_Y)        : G1,G2,G5,G6,G8
%   ・縮約しない母線の番号(obj.noreduced_bus) : G8
%

% シミュレーションで使う各条件のindexを取得
    V0bus       = unique( union(obj.additional_V0bus(:)' ,obj.fault.get_bus_list   ), 'sorted'); % G1,G2,G5,G6 母線電圧=0の制約を受ける母線番号の取得
    I0bus       = unique( union(obj.additional_I0bus(:)' ,obj.parallel.get_bus_list), 'sorted'); % G1,G3,G5,G7 母線電流=0の制約を受ける母線番号の取得
    no_empty    = find( ~tools.hcellfun(@(b) isa(b.component,'component.empty'), net.a_bus) );   % G5,G6,G7,G8 non-unit-busではない母線番号
    is_pararell = setdiff(no_empty,I0bus);                                                       % G6,G8
    idx_Y       = union(is_pararell,V0bus);                                                      % G1,G2,G5,G6,G8 non-unit-busの母線から解列した母線を除いた母線番号
    
    obj.noreduced_bus = setdiff(idx_Y, V0bus);                                              % G8
    if obj.isCalculated_disconnected_mac
        obj.simulated_bus = no_empty;                                                            % G5,G6,G7,G8
    else
        obj.simulated_bus = is_pararell;                                                         % G6,G8
    end

    obj.I0const_bus = intersect(I0bus, obj.simulated_bus); 
    obj.V0const_bus = intersect(V0bus, is_pararell);


% 接続しているbranch・controllerのindexを取得
    connect_branch   = find( tools.hcellfun(@(b) strcmp(b.parallel,'on'), net.a_branch) );
    obj.simulated_cl = find( tools.hcellfun(@(c) strcmp(c.parallel,'on'), net.a_controller_local) );
    obj.simulated_cg = find( tools.hcellfun(@(c) strcmp(c.parallel,'on'), net.a_controller_global));


% アドミタンス行列を定義
    [Y, obj.Ymat_all] = net.get_admittance_matrix([],connect_branch);
    [~, Ymat_temp,~, Vmat_reproduce] = net.reduce_admittance_matrix(Y, idx_Y);
    idx_admittance     = ismember(kron(idx_Y(:),[1;1]), obj.noreduced_bus);
    obj.Ymat           = Ymat_temp(idx_admittance, idx_admittance);
    % 縮約後のベクトルから基のデータに復元するための行列を作成
    obj.Vmat_reproduce = Vmat_reproduce(:, idx_admittance);
    idx_admittance     = ismember(kron((1:numel(net.a_bus))',[1;1]), obj.noreduced_bus);
    obj.Imat_reproduce = zeros(size(obj.Vmat_reproduce));
    obj.Imat_reproduce(idx_admittance(:),:) = eye(sum(idx_admittance));


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