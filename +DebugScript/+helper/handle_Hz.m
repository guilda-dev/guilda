function Hz = handle_Hz(obj)
% 関数ハンドル f_dx に埋め込まれた周波数 omega0 (set_odefcn が obj.r_Hz から作る) を読む。
    s  = functions(obj.f_dx);
    Hz = s.workspace{1}.omega0;
end
