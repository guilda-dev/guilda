function MassMatrix = SimulationSetting(obj, idx_fault, idx_input)

    if nargin>1; obj.i_fault = reshape(sort(idx_fault),1,[]); end
    if nargin>2; obj.i_input = idx_input(:)'; end
    l_fault = false(1,obj.n_bus);
    l_fault(obj.i_fault) = true;
    
    net   = obj.power_network;

    % 各機器の接続状況を検証
        l_link_comp = tools.hcellfun(@(b)  b.component.is_connected, net.a_bus              );
        l_link_br   = tools.hcellfun(@(br)          br.is_connected, net.a_branch           );
        l_link_cl   = tools.hcellfun(@(c)            c.is_connected, net.a_controller_local );
        l_link_cg   = tools.hcellfun(@(c)            c.is_connected, net.a_controller_global);

    % odeで扱う変数のインデックスとの対応関係を表すlogical配列を作成

        % 1.各componentの状態
        x_mac = obj.cl_xmac_all;
        if ~obj.consider_dynamic_unlink_component
            obj.i_simulated_mac = find(~obj.l_nonunit & l_link_comp) ;
            x_mac(~l_link_comp) = {false(0,1)};
        else
            obj.i_simulated_mac = find(~obj.l_nonunit) ;
        end


        % 2.各 local controllerの状態
        x_cl = obj.cl_xcl_all;
        if obj.consider_dynamic_local_controller && obj.n_cl~= 0
            obj.i_simulated_cl = find(l_link_cl);
            x_cl(~l_link_cl) = {false(0,1)};
        else
            obj.i_simulated_cl = [];
        end

        %　3.各 global controllerの状態
        x_cg = obj.cl_xcg_all;
        if obj.consider_dynamic_global_controller && obj.n_cg~= 0
            obj.i_simulated_cg = find(l_link_cg);
            x_cg(~l_link_cg) = {false(0,1)};
        else
            obj.i_simulated_cg = [];
        end

        % 4.(non-unit母線を除いた母線 or 地絡が起きている母線)の電圧
        obj.i_simulated_bus = find( (~obj.l_nonunit & l_link_comp) | l_fault) ;
        l_Iconst_at_fault_bus = l_fault & l_link_comp;
        temp = [obj.i_simulated_bus,zeros(1,sum(l_Iconst_at_fault_bus))];
        if obj.consider_dynamic_unlink_component
            temp = [temp,find(~l_link_comp)];
            obj.l_Vvirtual_unlink = ~l_link_comp;
        else
            obj.l_Vvirtual_unlink = false(size(l_link_comp));
        end        
        temp  = kron(temp(:),[1;1]);

        obj.l_Vall_simulated = false(size(temp));
        obj.l_Vall_simulated(1:2*numel(obj.i_simulated_bus)) = true;
        constraint = [tools.harrayfun(@(i) temp == i, [1:obj.n_bus,0]), obj.l_Vall_simulated];

        temp  = blkdiag(x_mac{:},x_cl{:},x_cg{:},constraint);
        obj.l_xmac_simulated = temp(:,  1:obj.n_bus);
        obj.l_xcg_simulated  = temp(:, (1:obj.n_cl ) +obj.n_bus);
        obj.l_xcg_simulated  = temp(:, (1:obj.n_cg ) +obj.n_bus +obj.n_cl);
        obj.l_constraint     = temp(:, (1:obj.n_bus) +obj.n_bus +obj.n_cl + obj.n_cg);
        obj.l_Ibus_fault     = {find(kron(l_Iconst_at_fault_bus(:),true(2,1))), ...
                                any(obj.l_constraint(:,l_Iconst_at_fault_bus),2), ...
                                temp(:,end-1)};
        obj.l_Vall_simulated = temp(:,end);
        obj.nX = size(temp,1);

        

    % 各componentの入力変数の個数についてもlogical配列を作成
    temp  = tools.arrayfun(@(i) true(net.a_bus{i}.component.get_nu,1), 1:numel(obj.i_input));
    obj.l_input = blkdiag(temp{:});

    [Y, obj.Ymat_all] = net.get_admittance_matrix(1:obj.n_bus, find(l_link_br));
    [~, obj.Ymat, ~, obj.Ymat_reproduce] = net.reduce_admittance_matrix(Y, obj.i_simulated_bus);
    
    n_constraint = size(constraint,1);
    n_dx  = obj.nX-n_constraint;
    MassMatrix = blkdiag(eye(n_dx), zeros(n_constraint));
end