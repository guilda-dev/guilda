function newFactory = blkdiag(obj,varargin)
    av_OdeFac = [{obj};varargin(:)];

    sv_state  = tools.vcellfun(@(c) c.x, av_OdeFac);
    sv_input  = tools.vcellfun(@(c) c.u, av_OdeFac);
    sv_output = tools.vcellfun(@(c) c.y, av_OdeFac);

    rv_xst    = tools.vcellfun(@(c) c.xst, av_OdeFac);
    rv_ust    = tools.vcellfun(@(c) c.ust, av_OdeFac);
    rv_yst    = tools.vcellfun(@(c) c.yst, av_OdeFac);

    rm_Mass   = tools.dcellfun(@(c) c.Mass,av_OdeFac);

    lm_xidx   = tools.dcellfun(@(c) c.x_id,av_OdeFac);
    lm_uidx   = tools.dcellfun(@(c) c.u_id,av_OdeFac);
    lm_yidx   = tools.dcellfun(@(c) c.y_id,av_OdeFac);

    fv_diff   = tools.vcellfun(@(c) c.eq_diff  , av_OdeFac);
    fv_output = tools.vcellfun(@(c) c.eq_output, av_OdeFac);
    fv_const  = tools.vcellfun(@(c) c.eq_const , av_OdeFac);

    % 入力ポートの重複を整理
    [sv_uinput, iv_uin ] = unique(sv_input ,"stable");

    % 状態変数の重複を検知
    nx_before = numel(sv_state);
    nx_after  = numel(unique(sv_state));
    assert(nx_before==nx_after, config.lang("状態変数が重複しています。","Duplicate state variable."))

    % 入出力の接続
    lv_unknown = true(1,numel(sv_output));
    l_change   = true;
    rm_io      = double( string(sv_input(iv_uin)) == string(sv_output)' );
    fv_outtemp = fv_output;
    while any(lv_unknown) && l_change
        l_change  = false;
        fv_uinput  = rm_io * fv_outtemp;
        fv_outtemp= simplify( subs(fv_outtemp, sv_uinput, fv_uinput) );
        for i_out = find(lv_unknown)
            sv_ivar = symvar(fv_outtemp(i_out));
            if isempty(sv_ivar) || all(ismember(sv_ivar, [sv_state;sym("Time")]))
                lv_unknown(i_out) = false;
                l_change = true;
            end
        end
    end
    assert( any(lv_unknown), config.lang("オブジェクト同士の入出力の接続が解決できませんでした。複数のオブジェクトの出力方程式内で相互参照が存在する可能性があります。", ...
                                         "Could not resolve input/output connections between objects. Cross-references may exist within the output equations of multiple objects."))
    fv_input = rm_io * fv_outtemp;
    fv_diff  = simplify( subs(fv_diff  , sv_uinput, sv_uinput+fv_input) );
    fv_output= simplify( subs(fv_output, sv_uinput, sv_uinput+fv_input) );
    fv_const = simplify( subs(fv_const , sv_uinput, sv_uinput+fv_input) );

    % 統合後の新たなDaeFactoryクラスを作成
    newFactory = supporters.DaeFactory( sv_state, sv_input, sv_output, "idx_state",lm_xidx, "idx_input",lm_uidx, "idx_output",lm_yidx );
    newFactory.set_equilibrium( rv_xst, rv_ust, rv_yst );
    newFactory.set_equations( fv_diff, fv_output, fv_const, "Mass",rm_Mass);
    newFactory.Comment = tools.vcellfun(@(c) c.Comment , av_OdeFac);
end