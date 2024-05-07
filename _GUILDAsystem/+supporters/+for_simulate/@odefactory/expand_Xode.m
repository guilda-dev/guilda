function [x, xcl, xcg, V, I, Vvirtual] = expand_Xode(obj,xsys,idx_mac,idx_cl,idx_cg, tidx,uidx_mac,uidx_cl,uidx_cg)
    net = obj.network;
    nbus = numel(idx_mac);
    tdim = size(xsys,2);
    
    % (編集中)
    % if nargin<6
    %     tidx     = [];
    %     uidx_mac = [];
    %     uidx_cl  = [];
    %     uidx_cg  = [];
    % end
    %      
    % 必要に応じてインデックスを整理
    %
    % uidx controller global : idx_cg  + [idx_macをidx_inputに含むcg]
    % uidx controller local  : idx_cl  + [idx_macをidx_inputに含むcl]
    % uidx component         : idx_mac 
    %
    % xidx controller global : idx_cg  + [idx_macを含むcg]
    % xidx controller local  : idx_cl  + [idx_macを含むcl]
    % xidx component         : idx_mac + [idx_cg,idx_cl内のidx_observeに含まれる機器番号]
    % Voltage,Current        : idx_mac + [idx_cg,idx_cl内のidx_observeに含まれる機器番号]
    

    
    
    [~, logical_mac] = ismember(idx_mac, obj.simulated_bus);
    [~, logical_cl ] = ismember(idx_cl , obj.simulated_cl );
    [~, logical_cg ] = ismember(idx_cg , obj.simulated_cg );

    x = cell( nbus, 1);
    for i = 1:nbus
        idx = idx_mac(i);
        if logical_mac(i)
            x{i} = xsys( obj.logimat.x(:,logical_mac(i)), :);
        else
            x{i} = nan( net.a_bus{idx}.component.get_nx, tdim);
        end
    end

    xcl = cell( numel(idx_cl), 1);
    for i = 1:numel(idx_cl)
        idx = idx_cl(i);
        if logical_cl(i)
            xcl{i} = xsys( obj.logimat.xcl(:,logical_cl(i)), :);
        else
            xcl{i} = nan( net.a_controller_local{idx}.get_nx, tdim);
        end
    end
    
    xcg = cell( numel(idx_cg), 1);
    for i = 1:numel(idx_cg)
        idx = idx_cg(i);
        if logical_cg(i)
            xcg{i} = xsys( obj.logimat.xcg(:,logical_cg(i)), :);
        else
            xcg{i} = nan( net.a_controller_global{idx}.get_nx, tdim);
        end
    end
    

    V = cell(nbus,1);
    I = cell(nbus,1);
    Vvirtual = cell(nbus,1);

    %temp0 = zeros(2,tdim);
    tempN = nan(2,tdim);

    idx_temp = reshape([-1;0] + 2*idx_mac(:)',[],1);
    Vred = xsys(obj.logimat.V,:);
    Vall = obj.Vmat_reproduce(idx_temp,:) * Vred;
    Iall = obj.Imat_reproduce(idx_temp,:) * obj.Ymat * Vred;

    I0 = xsys(obj.logimat.I0const,:);
    V0 = xsys(obj.logimat.V0const,:);

    [V0idx,V0num] = ismember( idx_mac,obj.V0const_bus);
    [I0idx,I0num] = ismember( idx_mac,obj.I0const_bus);
    
    for i = 1:numel(idx_mac)
        idx = idx_mac(i);

        number = [-1;0]+2*i;
        V{idx} = Vall(number,:);

        if V0idx(i); I{idx} = V0( [-1;0]+2*V0num(i), :);
        else;        I{idx} = Iall(number,:);
        end
        
        if  I0idx(i); Vvirtual{idx} = I0( [-1;0]+2*I0num(i), :);
        else;         Vvirtual{idx} = tempN;
        end
    end

end