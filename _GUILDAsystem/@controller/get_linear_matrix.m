function [A, BX, BV, BI,  BU, C, DX, DV, DI, DU] = get_linear_matrix(obj)
        
    %%% 平衡点の抽出 %%%
    xst = obj.get_x0;
    Xst = tools.arrayfun(@(i) obj.network.a_bus{i}.component.x_equilibrium           , obj.connected_index_input);
    Xst = tools.arrayfun(@(i) obj.idx_state{i}*Xst{i}                                , 1:numel(Xst)             );
    Vst = tools.arrayfun(@(i) tools.complex2vec(obj.network.a_bus{i}.V_equilibrium)  , obj.connected_index_input);
    Ist = tools.arrayfun(@(i) tools.complex2vec(obj.network.a_bus{i}.I_equilibrium)  , obj.connected_index_input);
    Ust = tools.arrayfun(@(i) obj.network.a_bus{i}.component.u_equilibrium, obj.connected_index_input);
    
    nx = numel(xst);
    nu = size( blkdiag(obj.idx_port{:}), 2);
    nmac = numel(Xst);

    %%% 時変システムでないかの検査 %%%
    t_dx = @(t) obj.get_dx_u(t, xst, Xst, Vst, Ist, Ust);
    [dx0,u0] = t_dx(0);
    [dx100,u100] = t_dx(100);
    u0   = vertcat( u0{:}   );
    u100 = vertcat( u100{:} );
    if ~ ( all( (dx0-dx100)<1e-4 ) && all( (u0-u100)<1e-4 ) )
        warning('時変システムであるようです. t=0において近似線形化を実行します.')
    end
        

    %%% 変数定義
    delta = 1e-6;
    

    %%% 行列を定義
    A   = nan(nx,nx);
    C   = nan(nu,nx);
    cBX = cell(1,nmac);
    cBV = cell(1,nmac);
    cBI = cell(1,nmac);
    cBU = cell(1,nmac);
    cDX = cell(1,nmac);
    cDV = cell(1,nmac);
    cDI = cell(1,nmac);
    cDU = cell(1,nmac);


    %%% 数値微分
    for i = 1:numel(xst)
        xsti = xst;
        xsti(i) = xsti(i) + delta;
        [dxi, ui] = obj.get_dx_u(0, xsti, Xst, Vst, Ist, Ust);
        A(:,i) = dxi/delta;
        C(:,i) = (vertcat(ui{:})-u0)/delta;
    end

    for i = 1:nmac
        Xsti   = Xst{i};
        nXi    = numel(Xsti);
        cBX{i} = nan(nx,nXi);
        cDX{i} = nan(nu,nXi);
        for xi = 1:nXi
            Xsti_ = Xsti;
            Xsti_(xi) = Xsti_(xi) + delta;
            Xst_ = Xst;
            Xst_{i} = Xsti_;
            [dxi, ui] = obj.get_dx_u(0, xst, Xst_, Vst, Ist, Ust);
            cBX{i}(:,xi) = dxi/delta;
            cDX{i}(:,xi) = (vertcat(ui{:})-u0)/delta;
        end

        Vsti   = Vst{i};
        nVi    = numel(Vsti);
        cBV{i} = nan(nx,nVi);
        cDV{i} = nan(nu,nVi);
        for vi = 1:nVi
            Vsti_ = Vsti;
            Vsti_(vi) = Vsti_(vi) + delta;
            Vst_ = Vst;
            Vst_{i} = Vsti_;
            [dxi, ui] = obj.get_dx_u(0, xst, Xst, Vst_, Ist, Ust);
            cBV{i}(:,vi) = dxi/delta;
            cDV{i}(:,vi) = (vertcat(ui{:})-u0)/delta;
        end

        Isti   = Ist{i};
        nIi    = numel(Isti);
        cBI{i} = nan(nx,nIi);
        cDI{i} = nan(nu,nIi);
        for ii = 1:nIi
            Isti_     = Isti;
            Isti_(ii) = Isti_(ii) + delta;
            Ist_    = Ist;
            Ist_{i} = Isti_;
            [dxi, ui] = obj.get_dx_u(0, xst, Xst, Vst, Ist_, Ust);
            cBI{i}(:,ii) = dxi/delta;
            cDI{i}(:,ii) = (vertcat(ui{:})-u0)/delta;
        end

        Usti   = Ust{i};
        nUi    = numel(Usti);
        cBU{i} = nan(nx,nUi);
        cDU{i} = nan(nu,nUi);
        for uidx = 1:nUi
            Usti_       = Usti;
            Usti_(uidx) = Usti_(uidx) + delta;
            Ust_    = Ust;
            Ust_{i} = Usti_;
            [dxi, ui] = obj.get_dx_u(0, xst, Xst, Vst, Ist, Ust_);
            cBU{i}(:,uidx) = dxi/delta;
            cDU{i}(:,uidx) = (vertcat(ui{:})-u0)/delta;
        end
    end


    %%% 出力用の変数に変換
    BX = horzcat(cBX{:});
    BV = horzcat(cBV{:});
    BI = horzcat(cBI{:});
    BU = horzcat(cBU{:});
    DX = horzcat(cDX{:});
    DV = horzcat(cDV{:});
    DI = horzcat(cDI{:});
    DU = horzcat(cDU{:});