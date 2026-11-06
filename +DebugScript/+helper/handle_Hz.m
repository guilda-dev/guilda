function Hz = handle_Hz(obj)
% 関数ハンドル f_dx に埋め込まれた周波数 omega0 (apply_edit("odefcn") が obj.get_Hz() から作る) を読む。
    arguments (Input)
        obj
    end
    arguments (Output)
        Hz  % [Hz] f_dx に埋め込まれた周波数
    end
    s  = functions(obj.f_dx);
    Hz = s.workspace{1}.omega0;
end
