function out = blkdiag(obj,varargin)
    cls      = [{obj};varargin(:)];
    xvar     = string( tools.vcellfun(@(c) c.x, cls) );
    xsubuni  = unique( string( tools.vcellfun(@(c) c.xsub, cls) ), "stable");
    rowA     = unique( string( tools.vcellfun(@(c) c.A.Row, cls) ), "stable");
    rowAeq   = unique( string( tools.vcellfun(@(c) c.Aeq.Row, cls) ), "stable");
    rownleq  = unique( string( tools.vcellfun(@(c) c.nonleq.Row, cls) ), "stable");
    rownlneq = unique( string( tools.vcellfun(@(c) c.nonlneq.Row, cls) ), "stable");
    xuni     = unique(   xvar, "stable");
    xsubuni  = xsubuni(~ismember(xsubuni,xuni));

    % validation
    assert(numel(xuni)==numel(xvar), config.lang("決定変数の重複が検出されました","Overlapping variables detected."))

    % 統合後の新たなOptimFactoryクラスを作成
    out  = supporters.for_optim.OptimFactory(xuni,xsubuni);
    out.Tag = tools.vcellfun(@(c) c.Tag, cls);
    
    % 行列定義
    xall     = [xuni;xsubuni];
    nx       = numel(xuni);
    nxall    = numel(xall);
    H_       = array2table( zeros(           nxall, nxall ), "RowNames",     xall,"VariableNames",  xall);
    f_       = array2table( zeros(           nxall,    1  ), "RowNames",     xall,"VariableNames",  "f" );
    x0_      = array2table( zeros(              nx,    1  ), "RowNames",     xuni,"VariableNames",  "x0");
    lb_      = array2table( zeros(              nx,    1  ), "RowNames",     xuni,"VariableNames",  "lb");
    ub_      = array2table( zeros(              nx,    1  ), "RowNames",     xuni,"VariableNames",  "ub");
    A_       = array2table( zeros( numel(rowA)    , nxall ), "RowNames",     rowA,"VariableNames",  xall);
    b_       = array2table( zeros( numel(rowA)    ,    1  ), "RowNames",     rowA,"VariableNames",  "b");
    Aeq_     = array2table( zeros( numel(rowAeq)  , nxall ), "RowNames",   rowAeq,"VariableNames",  xall);
    beq_     = array2table( zeros( numel(rowAeq)  ,    1  ), "RowNames",   rowAeq,"VariableNames", "beq");
    nonleq_  = array2table( zeros( numel(rownleq) ,    1  ), "RowNames",  rownleq,"VariableNames", "con");
    nonlneq_ = array2table( zeros( numel(rownlneq),    1  ), "RowNames", rownlneq,"VariableNames", "con");
    nonlobj_ = 0;
    % クラス毎にパラメータを抽出
    for  i = 1:numel(cls)
        icls = cls{i};
        % インデックスの抽出
        ix      = string( icls.x);
        ixall   = string([icls.x;icls.xsub]);
        iRA     = string( icls.A.Row );
        iRAeq   = string( icls.Aeq.Row );
        iRnleq  = string( icls.nonleq.Row );
        iRnlneq = string( icls.nonlneq.Row );
        % 値の抽出
        A_{ iRA, ixall} = A_{ iRA, ixall} + icls.A.Variables;
        b_{ iRA, 1    } = b_{ iRA, 1    } + icls.b.Variables;

        Aeq_{ iRAeq, ixall} = Aeq_{ iRAeq, ixall} + icls.Aeq.Variables;
        beq_{ iRAeq, 1    } = beq_{ iRAeq, 1    } + icls.beq.Variables;

        nonlneq_{ iRnlneq, 1}  = nonlneq_{ iRnlneq, 1} + icls.nonlneq.Variables;
        nonleq_{  iRnleq , 1}  = nonleq_{  iRnleq , 1} + icls.nonleq.Variables;

        H_{ ixall, ixall} =   H_{ ixall, ixall} + icls.H.Variables;
        f_{ ixall, 1    } =   f_{ ixall, 1    } + icls.f.Variables;
        x0_{ ix, 1} = icls.x0.Variables;
        lb_{ ix, 1} = icls.lb.Variables;
        ub_{ ix, 1} = icls.ub.Variables;
        
        nonlobj_ = nonlobj_ + icls.nonlobj.Variables;
    end

    % 新しく定義したoutにパラメータを代入
    out.add_eq(         Aeq_.Variables,beq_.Variables,rowAeq)
    out.add_neq(          A_.Variables,  b_.Variables,rowA  )
    out.add_nonleq(  nonleq_.Variables,    rownleq)
    out.add_nonlneq(nonlneq_.Variables,   rownlneq)
    out.H  = H_;
    out.f  = f_;
    out.x0 = x0_;
    out.lb = lb_;
    out.ub = ub_;
    out.nonlobj = nonlobj_;

end