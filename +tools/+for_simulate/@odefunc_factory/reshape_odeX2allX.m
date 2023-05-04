function [Xmac, Xcl, Xcg, Vall, Iall, Vvirtual] = reshape_odeX2allX( obj, ode_X)
    n_time = size(ode_X,2);

    l_xmac_all = blkdiag(obj.cl_xmac_all{:});
    l_xcl_all  = blkdiag(obj.cl_xcl_all{:});
    l_xcg_all  = blkdiag(obj.cl_xcg_all{:});

    Xmac = nan(size(l_xmac_all,1), n_time);
     Xcl = nan(size(l_xcl_all, 1), n_time);
     Xcg = nan(size(l_xcg_all, 1), n_time);


    Xmac(any(l_xmac_all(:,obj.i_simulated_mac),2),:) = ode_X(any(obj.l_xmac_simulated,2),:);
     Xcl(any(l_xcl_all( :,obj.i_simulated_cl ),2),:) = ode_X(any(obj.l_xcl_simulated ,2),:);
     Xcg(any(l_xcg_all( :,obj.i_simulated_cg ),2),:) = ode_X(any(obj.l_xcg_simulated ,2),:);

    Vred = ode_X(obj.l_Vall_simulated,:);
    Vall = obj.Ymat_reproduce * Vred;
    Iall = obj.Ymat_all       * Vall;
    Iall(obj.l_Ibus_fault{1},:) = ode_X(obj.l_Ibus_fault{3},:);

    Vvirtual = nan(2*obj.n_bus,n_time);
    idx_Vvirtual = any(obj.l_constraint(:,obj.l_Vvirtual_unlink),2);
    Vvirtual((kron(obj.l_Vvirtual_unlink(:),[1;1]))==1,:) = ode_X(idx_Vvirtual,:);
end
